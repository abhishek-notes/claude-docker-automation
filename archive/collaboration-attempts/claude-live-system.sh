#!/bin/bash

# Claude Live Real-time System - Actually Working Multi-Instance Communication
# This creates REAL working Claude instances that communicate in real-time

set -euo pipefail

DOCKER_IMAGE="claude-automation:latest"
CONFIG_VOLUME="claude-code-config"
LIVE_PORT=8081
CONTAINER_PREFIX="claude-live"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[LIVE]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
live() { echo -e "${PURPLE}[SYSTEM]${NC} $1"; }

# Create live collaboration server with real Claude instance management
create_live_server() {
    local workspace_dir="$1"
    local port="$2"
    
    log "Creating live Claude management server"
    
    mkdir -p "$workspace_dir/live-server"
    
    # Package.json for the live server
    cat > "$workspace_dir/live-server/package.json" << 'EOF'
{
  "name": "claude-live-system",
  "version": "1.0.0",
  "description": "Live Claude instance management and communication",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.7.2",
    "cors": "^2.8.5",
    "body-parser": "^1.20.2",
    "ws": "^8.13.0",
    "node-pty": "^0.10.1",
    "dockerode": "^3.3.5"
  }
}
EOF
    
    # Live server that manages actual Claude instances
    cat > "$workspace_dir/live-server/server.js" << 'EOF'
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const bodyParser = require('body-parser');
const Docker = require('dockerode');
const pty = require('node-pty');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: { origin: "*", methods: ["GET", "POST"] }
});

app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

const docker = new Docker();

// Store live Claude instances
const liveInstances = new Map();
const messageHistory = [];
const taskQueue = new Map();

// Create a new Claude instance
app.post('/api/create-instance', async (req, res) => {
  const { instanceId, role, task, projectPath } = req.body;
  
  try {
    console.log(`Creating live Claude instance: ${instanceId}`);
    
    // Create Docker container
    const container = await docker.createContainer({
      Image: 'claude-automation:latest',
      name: `claude-live-${instanceId}-${Date.now()}`,
      WorkingDir: '/workspace',
      Env: [
        'CLAUDE_INSTANCE_ID=' + instanceId,
        'CLAUDE_ROLE=' + role,
        'CLAUDE_TASK=' + task,
        'CLAUDE_CONFIG_DIR=/home/claude/.claude'
      ],
      HostConfig: {
        Binds: [
          'claude-code-config:/home/claude/.claude',
          `${projectPath}:/workspace`,
          `${process.env.HOME}/.claude.json:/tmp/host-claude.json:ro`
        ]
      },
      User: 'claude',
      Tty: true,
      OpenStdin: true,
      AttachStdout: true,
      AttachStderr: true,
      AttachStdin: true
    });
    
    await container.start();
    console.log(`Container started: ${container.id}`);
    
    // Create PTY connection to container
    const stream = await container.attach({
      stream: true, stdin: true, stdout: true, stderr: true
    });
    
    // Store instance info
    const instance = {
      id: instanceId,
      role,
      task,
      container,
      stream,
      status: 'starting',
      messages: [],
      created: Date.now()
    };
    
    liveInstances.set(instanceId, instance);
    
    // Setup stream handlers
    stream.on('data', (data) => {
      const output = data.toString();
      console.log(`[${instanceId}] ${output}`);
      
      // Broadcast output to connected clients
      io.emit('instanceOutput', {
        instanceId,
        output,
        timestamp: Date.now()
      });
      
      // Check for collaboration commands in output
      if (output.includes('COLLABORATE:')) {
        handleCollaborationCommand(instanceId, output);
      }
    });
    
    // Initialize Claude in the container
    const initScript = `
      # Setup environment
      sudo chown -R claude:claude /home/claude/.claude 2>/dev/null || true
      if [ -f "/tmp/host-claude.json" ]; then
        cp /tmp/host-claude.json /home/claude/.claude.json
        chmod 600 /home/claude/.claude.json
      fi
      git config --global init.defaultBranch main
      git config --global --add safe.directory /workspace
      
      echo "SYSTEM: Claude instance ${instanceId} (${role}) starting..."
      echo "SYSTEM: Task assigned: ${task}"
      echo "COLLABORATION: Instance ready for real-time communication"
      
      # Start Claude with collaboration prompt
      claude --dangerously-skip-permissions
    `;
    
    stream.write(initScript + '\n');
    
    instance.status = 'running';
    
    res.json({ 
      success: true, 
      instanceId, 
      containerId: container.id,
      status: 'running'
    });
    
    io.emit('instanceCreated', {
      instanceId,
      role,
      task,
      status: 'running'
    });
    
  } catch (error) {
    console.error('Error creating instance:', error);
    res.status(500).json({ error: error.message });
  }
});

// Send message to specific Claude instance
app.post('/api/send-to-claude', (req, res) => {
  const { instanceId, message, from } = req.body;
  
  const instance = liveInstances.get(instanceId);
  if (!instance) {
    return res.status(404).json({ error: 'Instance not found' });
  }
  
  console.log(`Sending message to ${instanceId}: ${message}`);
  
  // Format message for Claude
  const claudeMessage = `
COLLABORATION_MESSAGE from ${from || 'User'}:
${message}

Please respond with COLLABORATE: prefix if you want to send a message to another instance.
`;
  
  instance.stream.write(claudeMessage + '\n');
  
  // Store message
  const msgObj = {
    id: Date.now(),
    to: instanceId,
    from: from || 'User',
    content: message,
    timestamp: new Date().toISOString()
  };
  
  messageHistory.push(msgObj);
  instance.messages.push(msgObj);
  
  io.emit('messageSent', msgObj);
  
  res.json({ success: true, messageId: msgObj.id });
});

// Handle collaboration commands from Claude instances
function handleCollaborationCommand(fromInstance, output) {
  const collaborateMatch = output.match(/COLLABORATE:\s*(\w+):\s*(.+)/);
  if (!collaborateMatch) return;
  
  const [, targetInstance, message] = collaborateMatch;
  
  console.log(`Collaboration: ${fromInstance} -> ${targetInstance}: ${message}`);
  
  if (targetInstance === 'ALL') {
    // Send to all other instances
    liveInstances.forEach((instance, id) => {
      if (id !== fromInstance) {
        sendToInstance(id, `Message from ${fromInstance}: ${message}`, fromInstance);
      }
    });
  } else if (liveInstances.has(targetInstance)) {
    sendToInstance(targetInstance, message, fromInstance);
  }
  
  // Store collaboration message
  const msgObj = {
    id: Date.now(),
    from: fromInstance,
    to: targetInstance,
    content: message,
    type: 'collaboration',
    timestamp: new Date().toISOString()
  };
  
  messageHistory.push(msgObj);
  io.emit('collaborationMessage', msgObj);
}

function sendToInstance(instanceId, message, from) {
  const instance = liveInstances.get(instanceId);
  if (!instance) return;
  
  const formattedMessage = `
COLLABORATION_MESSAGE from ${from}:
${message}

Respond with COLLABORATE: [target]: [your message] to reply.
`;
  
  instance.stream.write(formattedMessage + '\n');
}

// Update task for an instance
app.post('/api/update-task', (req, res) => {
  const { instanceId, newTask } = req.body;
  
  const instance = liveInstances.get(instanceId);
  if (!instance) {
    return res.status(404).json({ error: 'Instance not found' });
  }
  
  console.log(`Updating task for ${instanceId}: ${newTask}`);
  
  const taskUpdate = `
TASK_UPDATE:
Your task has been updated to: ${newTask}

Please acknowledge this update and adjust your work accordingly.
`;
  
  instance.stream.write(taskUpdate + '\n');
  instance.task = newTask;
  
  io.emit('taskUpdated', { instanceId, newTask });
  
  res.json({ success: true });
});

// Get all instances
app.get('/api/instances', (req, res) => {
  const instances = Array.from(liveInstances.values()).map(inst => ({
    id: inst.id,
    role: inst.role,
    task: inst.task,
    status: inst.status,
    created: inst.created,
    messageCount: inst.messages.length
  }));
  
  res.json(instances);
});

// Get messages
app.get('/api/messages', (req, res) => {
  res.json(messageHistory.slice(-100)); // Last 100 messages
});

// Stop instance
app.post('/api/stop-instance', async (req, res) => {
  const { instanceId } = req.body;
  
  const instance = liveInstances.get(instanceId);
  if (!instance) {
    return res.status(404).json({ error: 'Instance not found' });
  }
  
  try {
    await instance.container.stop();
    await instance.container.remove();
    liveInstances.delete(instanceId);
    
    io.emit('instanceStopped', { instanceId });
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// WebSocket for real-time updates
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  socket.on('joinInstance', ({ instanceId }) => {
    socket.join(instanceId);
    console.log(`Client joined instance: ${instanceId}`);
  });
  
  socket.on('sendMessage', ({ instanceId, message }) => {
    const instance = liveInstances.get(instanceId);
    if (instance) {
      instance.stream.write(message + '\n');
    }
  });
  
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

const PORT = process.env.PORT || 8081;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Claude Live System running on port ${PORT}`);
  console.log(`Dashboard: http://localhost:${PORT}`);
});
EOF
    
    # Create web interface
    mkdir -p "$workspace_dir/live-server/public"
    cat > "$workspace_dir/live-server/public/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Claude Live System - Real-time Multi-Instance Control</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 0; background: #0a0a0a; color: #fff; }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        .header { display: flex; justify-content: between; align-items: center; margin-bottom: 30px; }
        .instances-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .instance { background: #1a1a1a; border: 1px solid #333; border-radius: 8px; padding: 20px; }
        .instance.running { border-left: 4px solid #00cc66; }
        .instance.stopped { border-left: 4px solid #cc3300; }
        .instance-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
        .instance-title { font-size: 18px; font-weight: bold; color: #66ccff; }
        .status { padding: 4px 12px; border-radius: 16px; font-size: 12px; font-weight: bold; }
        .status.running { background: #00cc66; color: white; }
        .status.stopped { background: #cc3300; color: white; }
        .output { background: #000; border: 1px solid #333; border-radius: 4px; height: 200px; overflow-y: auto; padding: 10px; font-family: 'Monaco', monospace; font-size: 12px; margin: 10px 0; }
        .controls { display: flex; gap: 10px; margin: 10px 0; }
        .btn { padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; font-size: 14px; }
        .btn-primary { background: #0066cc; color: white; }
        .btn-danger { background: #cc3300; color: white; }
        .btn-secondary { background: #666; color: white; }
        .message-input { width: 100%; padding: 8px; background: #333; border: 1px solid #555; color: white; border-radius: 4px; margin: 5px 0; }
        .create-form { background: #1a1a1a; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; color: #ccc; }
        .form-group input, .form-group textarea { width: 100%; padding: 8px; background: #333; border: 1px solid #555; color: white; border-radius: 4px; }
        .messages { background: #1a1a1a; padding: 20px; border-radius: 8px; height: 300px; overflow-y: auto; }
        .message { margin-bottom: 10px; padding: 8px; background: #2a2a2a; border-radius: 4px; }
        .message-header { font-size: 12px; color: #999; margin-bottom: 4px; }
        h1, h2 { color: #66ccff; }
    </style>
    <script src="/socket.io/socket.io.js"></script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🤖 Claude Live System - Real-time Multi-Instance Control</h1>
            <button class="btn btn-secondary" onclick="refreshInstances()">Refresh</button>
        </div>
        
        <div class="create-form">
            <h2>Create New Claude Instance</h2>
            <div style="display: grid; grid-template-columns: 1fr 1fr 2fr 1fr; gap: 15px;">
                <div class="form-group">
                    <label>Instance ID</label>
                    <input type="text" id="instanceId" placeholder="alice, bob, etc.">
                </div>
                <div class="form-group">
                    <label>Role</label>
                    <input type="text" id="role" placeholder="Backend Analyst">
                </div>
                <div class="form-group">
                    <label>Task</label>
                    <input type="text" id="task" placeholder="Analyze Medusa backend architecture">
                </div>
                <div class="form-group">
                    <label>&nbsp;</label>
                    <button class="btn btn-primary" onclick="createInstance()">Create Instance</button>
                </div>
            </div>
        </div>
        
        <div id="instances" class="instances-grid"></div>
        
        <div class="messages">
            <h2>Real-time Communication Log</h2>
            <div id="messageLog"></div>
        </div>
    </div>

    <script>
        const socket = io();
        let instances = new Map();
        
        // Default project path - update this for your setup
        const DEFAULT_PROJECT_PATH = '/Users/abhishek/Work/palladio-software-25';
        
        async function createInstance() {
            const instanceId = document.getElementById('instanceId').value;
            const role = document.getElementById('role').value;
            const task = document.getElementById('task').value;
            
            if (!instanceId || !role || !task) {
                alert('Please fill all fields');
                return;
            }
            
            try {
                const response = await fetch('/api/create-instance', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        instanceId,
                        role,
                        task,
                        projectPath: DEFAULT_PROJECT_PATH
                    })
                });
                
                if (response.ok) {
                    document.getElementById('instanceId').value = '';
                    document.getElementById('role').value = '';
                    document.getElementById('task').value = '';
                    refreshInstances();
                } else {
                    alert('Failed to create instance');
                }
            } catch (error) {
                alert('Error: ' + error.message);
            }
        }
        
        async function sendMessage(instanceId) {
            const input = document.getElementById(`msg-${instanceId}`);
            const message = input.value.trim();
            if (!message) return;
            
            try {
                await fetch('/api/send-to-claude', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        instanceId,
                        message,
                        from: 'User'
                    })
                });
                
                input.value = '';
                addToOutput(instanceId, `[USER] ${message}`);
            } catch (error) {
                alert('Error sending message: ' + error.message);
            }
        }
        
        async function updateTask(instanceId) {
            const newTask = prompt('Enter new task:');
            if (!newTask) return;
            
            try {
                await fetch('/api/update-task', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ instanceId, newTask })
                });
            } catch (error) {
                alert('Error updating task: ' + error.message);
            }
        }
        
        async function stopInstance(instanceId) {
            if (!confirm(`Stop instance ${instanceId}?`)) return;
            
            try {
                await fetch('/api/stop-instance', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ instanceId })
                });
                refreshInstances();
            } catch (error) {
                alert('Error stopping instance: ' + error.message);
            }
        }
        
        function addToOutput(instanceId, text) {
            const output = document.getElementById(`output-${instanceId}`);
            if (output) {
                output.innerHTML += text + '\n';
                output.scrollTop = output.scrollHeight;
            }
        }
        
        async function refreshInstances() {
            try {
                const response = await fetch('/api/instances');
                const instancesData = await response.json();
                
                const container = document.getElementById('instances');
                container.innerHTML = '';
                
                instancesData.forEach(instance => {
                    const div = document.createElement('div');
                    div.className = `instance ${instance.status}`;
                    div.innerHTML = `
                        <div class="instance-header">
                            <div class="instance-title">${instance.id}</div>
                            <div class="status ${instance.status}">${instance.status}</div>
                        </div>
                        <div><strong>Role:</strong> ${instance.role}</div>
                        <div><strong>Task:</strong> ${instance.task}</div>
                        <div><strong>Messages:</strong> ${instance.messageCount}</div>
                        <div class="output" id="output-${instance.id}"></div>
                        <div class="controls">
                            <input type="text" class="message-input" id="msg-${instance.id}" placeholder="Send message to ${instance.id}..." onkeypress="if(event.key==='Enter') sendMessage('${instance.id}')">
                            <button class="btn btn-primary" onclick="sendMessage('${instance.id}')">Send</button>
                            <button class="btn btn-secondary" onclick="updateTask('${instance.id}')">Update Task</button>
                            <button class="btn btn-danger" onclick="stopInstance('${instance.id}')">Stop</button>
                        </div>
                    `;
                    container.appendChild(div);
                    
                    instances.set(instance.id, instance);
                });
            } catch (error) {
                console.error('Error refreshing instances:', error);
            }
        }
        
        function addMessage(message) {
            const log = document.getElementById('messageLog');
            const div = document.createElement('div');
            div.className = 'message';
            div.innerHTML = `
                <div class="message-header">${message.from} → ${message.to} | ${new Date(message.timestamp).toLocaleTimeString()}</div>
                <div>${message.content}</div>
            `;
            log.appendChild(div);
            log.scrollTop = log.scrollHeight;
        }
        
        // Socket events
        socket.on('instanceOutput', ({ instanceId, output }) => {
            addToOutput(instanceId, output);
        });
        
        socket.on('messageSent', addMessage);
        socket.on('collaborationMessage', addMessage);
        
        socket.on('instanceCreated', () => {
            refreshInstances();
        });
        
        // Initialize
        refreshInstances();
        
        // Load recent messages
        fetch('/api/messages')
            .then(r => r.json())
            .then(messages => messages.forEach(addMessage));
    </script>
</body>
</html>
EOF
    
    log "✅ Live server created with real-time Claude instance management"
}

# Start the live system
start_live_system() {
    local workspace_dir="${1:-/tmp/claude-live-system}"
    local port="${2:-$LIVE_PORT}"
    
    live "Starting Claude Live System on port $port"
    
    # Create workspace
    mkdir -p "$workspace_dir"
    
    # Create the live server
    create_live_server "$workspace_dir" "$port"
    
    # Start server
    cd "$workspace_dir/live-server"
    
    # Install dependencies and start
    if command -v npm &> /dev/null; then
        npm install
        echo "Starting live server..."
        node server.js &
        SERVER_PID=$!
        echo $SERVER_PID > "$workspace_dir/server.pid"
    else
        # Use Docker to run the server
        docker run -d \
            --name "claude-live-server" \
            -p "$port:8081" \
            -v "$workspace_dir:/app" \
            -v "/var/run/docker.sock:/var/run/docker.sock" \
            -w "/app/live-server" \
            node:18-alpine \
            sh -c "
                apk add --no-cache docker-cli &&
                npm install && 
                node server.js
            "
    fi
    
    sleep 5
    
    # Check if server is running
    if curl -s "http://localhost:$port" > /dev/null; then
        live "✅ Claude Live System running!"
        live "🌐 Dashboard: http://localhost:$port"
        live "🎮 You can now create and control multiple Claude instances"
        
        # Open the dashboard
        open "http://localhost:$port"
        
        echo ""
        echo -e "${CYAN}🚀 READY TO USE:${NC}"
        echo "1. Go to http://localhost:$port"
        echo "2. Create Claude instances with different roles"
        echo "3. Send messages directly to any Claude instance"
        echo "4. Watch them collaborate in real-time"
        echo "5. Update tasks on the fly"
        echo ""
        
    else
        error "Failed to start live system"
        return 1
    fi
}

# Quick demo setup
quick_demo() {
    local project_path="/Users/abhishek/Work/palladio-software-25"
    
    live "Setting up quick demo with Palladio project"
    
    start_live_system "/tmp/claude-live-demo" "$LIVE_PORT"
    
    echo ""
    echo -e "${YELLOW}Quick Demo Setup:${NC}"
    echo "1. Dashboard is opening at http://localhost:$LIVE_PORT"
    echo "2. Create these instances:"
    echo ""
    echo -e "${CYAN}Instance 1:${NC}"
    echo "   ID: alice"
    echo "   Role: Backend Architect"
    echo "   Task: Analyze Medusa backend and Salesforce integration"
    echo ""
    echo -e "${CYAN}Instance 2:${NC}"
    echo "   ID: bob"
    echo "   Role: Frontend Specialist"
    echo "   Task: Analyze Next.js frontend and Strapi CMS integration"
    echo ""
    echo "3. Send messages like:"
    echo "   'Analyze the authentication flow in the API'"
    echo "   'Check for any security issues'"
    echo "   'How does the frontend handle errors?'"
    echo ""
    echo "4. Watch them communicate with each other!"
}

# Stop live system
stop_live_system() {
    local workspace_dir="${1:-/tmp/claude-live-system}"
    
    live "Stopping Claude Live System..."
    
    # Stop server
    if [ -f "$workspace_dir/server.pid" ]; then
        kill $(cat "$workspace_dir/server.pid") 2>/dev/null || true
        rm "$workspace_dir/server.pid"
    fi
    
    # Stop Docker containers
    docker stop claude-live-server 2>/dev/null || true
    docker rm claude-live-server 2>/dev/null || true
    
    # Stop all live Claude instances
    docker ps --filter name=claude-live -q | xargs -r docker stop
    docker ps -a --filter name=claude-live -q | xargs -r docker rm
    
    live "✅ Live system stopped"
}

# Help
show_help() {
    cat << 'EOF'
Claude Live System - Real Working Multi-Instance Communication

This creates ACTUAL running Claude instances that communicate in real-time.

COMMANDS:
    start [workspace] [port]  - Start the live system
    demo                     - Quick demo setup
    stop [workspace]         - Stop all instances and server
    help                     - Show this help

FEATURES:
    🤖 Create multiple REAL Claude instances
    💬 Send messages directly to any Claude instance  
    🔄 Real-time communication between Claude instances
    📝 Update tasks while Claude is running
    🌐 Web dashboard for full control
    📊 Live output monitoring
    🎮 Interactive control interface

USAGE:
    1. ./claude-live-system.sh start
    2. Open http://localhost:8081
    3. Create Claude instances with different roles
    4. Send messages and watch them collaborate!

EXAMPLES:
    # Start the live system
    ./claude-live-system.sh start

    # Quick demo
    ./claude-live-system.sh demo

    # Stop everything
    ./claude-live-system.sh stop

This is REAL multi-Claude collaboration - not just scripts!
EOF
}

# Main function
case "${1:-demo}" in
    "start")
        start_live_system "${2:-}" "${3:-$LIVE_PORT}"
        ;;
    "demo")
        quick_demo
        ;;
    "stop")
        stop_live_system "${2:-}"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        quick_demo
        ;;
esac