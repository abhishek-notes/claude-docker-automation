#!/bin/bash

# Claude Real-time Collaboration System
# Advanced multi-instance communication with real-time messaging

set -euo pipefail

DOCKER_IMAGE="claude-automation:latest"
CONFIG_VOLUME="claude-code-config"
COLLAB_PORT_START=8080
CONTAINER_PREFIX="claude-realtime"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
realtime() { echo -e "${CYAN}[REALTIME]${NC} $1"; }

# Create collaboration server
create_collaboration_server() {
    local workspace_dir="$1"
    local port="${2:-8080}"
    
    log "Creating collaboration server at port $port"
    
    mkdir -p "$workspace_dir/server"
    
    # Create Node.js collaboration server
    cat > "$workspace_dir/server/package.json" << 'EOF'
{
  "name": "claude-collaboration-server",
  "version": "1.0.0",
  "description": "Real-time collaboration server for Claude instances",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.7.2",
    "cors": "^2.8.5",
    "body-parser": "^1.20.2"
  }
}
EOF
    
    cat > "$workspace_dir/server/server.js" << 'EOF'
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

// Store active Claude instances
const claudeInstances = new Map();
const messageHistory = [];
const sharedState = {};

// Claude instance registration
app.post('/api/register', (req, res) => {
  const { instanceId, role, capabilities } = req.body;
  claudeInstances.set(instanceId, {
    id: instanceId,
    role,
    capabilities,
    lastSeen: Date.now(),
    status: 'online'
  });
  
  console.log(`Claude instance registered: ${instanceId} (${role})`);
  io.emit('instanceRegistered', { instanceId, role, capabilities });
  res.json({ success: true, instances: Array.from(claudeInstances.values()) });
});

// Message broadcasting
app.post('/api/message', (req, res) => {
  const { from, to, type, content, metadata } = req.body;
  const message = {
    id: Date.now(),
    from,
    to,
    type,
    content,
    metadata,
    timestamp: new Date().toISOString()
  };
  
  messageHistory.push(message);
  console.log(`Message from ${from} to ${to}: ${type}`);
  
  if (to === 'all') {
    io.emit('message', message);
  } else {
    io.emit('message', message);
  }
  
  res.json({ success: true, messageId: message.id });
});

// Shared state management
app.post('/api/state', (req, res) => {
  const { key, value, instanceId } = req.body;
  sharedState[key] = { value, updatedBy: instanceId, timestamp: Date.now() };
  
  io.emit('stateUpdate', { key, value, updatedBy: instanceId });
  res.json({ success: true });
});

app.get('/api/state', (req, res) => {
  res.json(sharedState);
});

// Get message history
app.get('/api/messages', (req, res) => {
  const { since, instanceId } = req.query;
  let messages = messageHistory;
  
  if (since) {
    messages = messages.filter(m => new Date(m.timestamp) > new Date(since));
  }
  
  if (instanceId) {
    messages = messages.filter(m => m.to === instanceId || m.to === 'all' || m.from === instanceId);
  }
  
  res.json(messages);
});

// File sharing
app.post('/api/files', (req, res) => {
  const { filename, content, sharedBy } = req.body;
  const filePath = path.join('/collaboration/shared', filename);
  
  fs.writeFileSync(filePath, content);
  
  io.emit('fileShared', { filename, sharedBy, timestamp: new Date().toISOString() });
  res.json({ success: true });
});

// WebSocket connections
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  socket.on('join', ({ instanceId }) => {
    socket.join(instanceId);
    socket.instanceId = instanceId;
    console.log(`Claude instance ${instanceId} joined`);
  });
  
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
    if (socket.instanceId) {
      const instance = claudeInstances.get(socket.instanceId);
      if (instance) {
        instance.status = 'offline';
        io.emit('instanceDisconnected', socket.instanceId);
      }
    }
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    instances: claudeInstances.size,
    messages: messageHistory.length,
    uptime: process.uptime()
  });
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Claude Collaboration Server running on port ${PORT}`);
  console.log(`Dashboard: http://localhost:${PORT}`);
});
EOF
    
    # Create web dashboard
    mkdir -p "$workspace_dir/server/public"
    cat > "$workspace_dir/server/public/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Claude Collaboration Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #1e1e1e; color: #fff; }
        .container { max-width: 1200px; margin: 0 auto; }
        .instances { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .instance { background: #2d2d2d; padding: 20px; border-radius: 8px; border-left: 4px solid #0066cc; }
        .instance.online { border-left-color: #00cc66; }
        .instance.offline { border-left-color: #cc6600; }
        .messages { background: #2d2d2d; padding: 20px; border-radius: 8px; height: 400px; overflow-y: auto; }
        .message { margin-bottom: 15px; padding: 10px; background: #3d3d3d; border-radius: 4px; }
        .message-header { font-weight: bold; color: #66ccff; margin-bottom: 5px; }
        .message-content { color: #cccccc; }
        .status { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 12px; }
        .status.online { background: #00cc66; color: white; }
        .status.offline { background: #cc6600; color: white; }
        h1, h2 { color: #66ccff; }
    </style>
    <script src="/socket.io/socket.io.js"></script>
</head>
<body>
    <div class="container">
        <h1>🤝 Claude Collaboration Dashboard</h1>
        
        <h2>Active Instances</h2>
        <div id="instances" class="instances"></div>
        
        <h2>Real-time Communication</h2>
        <div id="messages" class="messages"></div>
    </div>

    <script>
        const socket = io();
        const instancesDiv = document.getElementById('instances');
        const messagesDiv = document.getElementById('messages');
        
        let instances = new Map();
        
        function updateInstances() {
            instancesDiv.innerHTML = '';
            instances.forEach(instance => {
                const div = document.createElement('div');
                div.className = `instance ${instance.status}`;
                div.innerHTML = `
                    <h3>${instance.id} <span class="status ${instance.status}">${instance.status}</span></h3>
                    <p><strong>Role:</strong> ${instance.role}</p>
                    <p><strong>Capabilities:</strong> ${instance.capabilities?.join(', ') || 'N/A'}</p>
                    <p><strong>Last Seen:</strong> ${new Date(instance.lastSeen).toLocaleTimeString()}</p>
                `;
                instancesDiv.appendChild(div);
            });
        }
        
        function addMessage(message) {
            const div = document.createElement('div');
            div.className = 'message';
            div.innerHTML = `
                <div class="message-header">
                    ${message.from} → ${message.to} | ${message.type} | ${new Date(message.timestamp).toLocaleTimeString()}
                </div>
                <div class="message-content">${JSON.stringify(message.content, null, 2)}</div>
            `;
            messagesDiv.appendChild(div);
            messagesDiv.scrollTop = messagesDiv.scrollHeight;
        }
        
        // Socket events
        socket.on('instanceRegistered', (data) => {
            instances.set(data.instanceId, {...data, status: 'online', lastSeen: Date.now()});
            updateInstances();
        });
        
        socket.on('instanceDisconnected', (instanceId) => {
            if (instances.has(instanceId)) {
                instances.get(instanceId).status = 'offline';
                updateInstances();
            }
        });
        
        socket.on('message', addMessage);
        
        // Load initial data
        fetch('/api/messages').then(r => r.json()).then(messages => {
            messages.forEach(addMessage);
        });
        
        // Refresh instances every 5 seconds
        setInterval(() => {
            fetch('/health').then(r => r.json()).then(data => {
                // Update instance data
            });
        }, 5000);
    </script>
</body>
</html>
EOF
    
    log "✅ Collaboration server created at: $workspace_dir/server"
    log "📊 Dashboard will be available at: http://localhost:$port"
}

# Start collaboration server
start_collaboration_server() {
    local workspace_dir="$1"
    local port="${2:-8080}"
    
    realtime "Starting collaboration server on port $port"
    
    # Check if Node.js is available
    if ! command -v node &> /dev/null; then
        error "Node.js not found. Installing in Docker container..."
        
        # Start server in Docker container
        docker run -d \
            --name "claude-collab-server" \
            -p "$port:8080" \
            -v "$workspace_dir:/collaboration" \
            -w "/collaboration/server" \
            node:18-alpine \
            sh -c "
                npm install && 
                echo 'Collaboration server starting...' &&
                node server.js
            "
    else
        # Start locally
        cd "$workspace_dir/server"
        npm install
        PORT=$port node server.js &
        SERVER_PID=$!
        echo $SERVER_PID > "$workspace_dir/server.pid"
    fi
    
    sleep 3
    
    if curl -s "http://localhost:$port/health" > /dev/null; then
        realtime "✅ Collaboration server running at http://localhost:$port"
        realtime "📊 Dashboard: http://localhost:$port"
    else
        error "Failed to start collaboration server"
        return 1
    fi
}

# Create collaboration client for Claude instances
create_claude_client() {
    local workspace_dir="$1"
    local server_url="${2:-http://localhost:8080}"
    
    mkdir -p "$workspace_dir/client"
    
    cat > "$workspace_dir/client/claude-client.js" << 'EOF'
const http = require('http');
const fs = require('fs');

class ClaudeCollaborationClient {
    constructor(instanceId, role, serverUrl = 'http://localhost:8080') {
        this.instanceId = instanceId;
        this.role = role;
        this.serverUrl = serverUrl;
        this.capabilities = ['code-analysis', 'documentation', 'problem-solving'];
        this.messageQueue = [];
    }
    
    async register() {
        const response = await this.makeRequest('/api/register', 'POST', {
            instanceId: this.instanceId,
            role: this.role,
            capabilities: this.capabilities
        });
        console.log(`Registered as ${this.instanceId} (${this.role})`);
        return response;
    }
    
    async sendMessage(to, type, content, metadata = {}) {
        const response = await this.makeRequest('/api/message', 'POST', {
            from: this.instanceId,
            to,
            type,
            content,
            metadata
        });
        console.log(`Sent ${type} message to ${to}`);
        return response;
    }
    
    async getMessages(since = null) {
        const url = `/api/messages?instanceId=${this.instanceId}${since ? `&since=${since}` : ''}`;
        const response = await this.makeRequest(url, 'GET');
        return response;
    }
    
    async updateSharedState(key, value) {
        const response = await this.makeRequest('/api/state', 'POST', {
            key,
            value,
            instanceId: this.instanceId
        });
        console.log(`Updated shared state: ${key}`);
        return response;
    }
    
    async getSharedState() {
        const response = await this.makeRequest('/api/state', 'GET');
        return response;
    }
    
    async shareFile(filename, content) {
        const response = await this.makeRequest('/api/files', 'POST', {
            filename,
            content,
            sharedBy: this.instanceId
        });
        console.log(`Shared file: ${filename}`);
        return response;
    }
    
    async makeRequest(path, method = 'GET', body = null) {
        return new Promise((resolve, reject) => {
            const url = new URL(this.serverUrl + path);
            const options = {
                hostname: url.hostname,
                port: url.port,
                path: url.pathname + url.search,
                method,
                headers: {
                    'Content-Type': 'application/json'
                }
            };
            
            const req = http.request(options, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => {
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        resolve(data);
                    }
                });
            });
            
            req.on('error', reject);
            
            if (body) {
                req.write(JSON.stringify(body));
            }
            
            req.end();
        });
    }
}

// Export for use in Claude containers
if (typeof module !== 'undefined') {
    module.exports = ClaudeCollaborationClient;
}

// CLI usage
if (require.main === module) {
    const [,, instanceId, role, action, ...args] = process.argv;
    
    if (!instanceId || !role) {
        console.log('Usage: node claude-client.js <instanceId> <role> <action> [args...]');
        console.log('Actions: register, send, get-messages, share-file');
        process.exit(1);
    }
    
    const client = new ClaudeCollaborationClient(instanceId, role);
    
    switch (action) {
        case 'register':
            client.register().then(console.log);
            break;
        case 'send':
            const [to, type, content] = args;
            client.sendMessage(to, type, content).then(console.log);
            break;
        case 'get-messages':
            client.getMessages().then(messages => {
                messages.forEach(m => console.log(`[${m.from}→${m.to}] ${m.type}: ${JSON.stringify(m.content)}`));
            });
            break;
        case 'share-file':
            const [filename] = args;
            const fileContent = fs.readFileSync(filename, 'utf8');
            client.shareFile(filename, fileContent).then(console.log);
            break;
        default:
            console.log('Unknown action:', action);
    }
}
EOF
    
    log "✅ Claude collaboration client created"
}

# Enhanced Claude instance with real-time collaboration
start_realtime_claude() {
    local instance_name="$1"
    local project_path="$2"
    local workspace_dir="$3"
    local task_description="$4"
    local role="$5"
    local server_port="${6:-8080}"
    
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${instance_name}-${session_id}"
    local server_url="http://host.docker.internal:$server_port"
    
    realtime "Starting real-time Claude instance: $instance_name"
    
    # Environment variables
    local env_vars=(
        -e "CLAUDE_CONFIG_DIR=/home/claude/.claude"
        -e "CLAUDE_INSTANCE_NAME=$instance_name"
        -e "CLAUDE_INSTANCE_ROLE=$role"
        -e "COLLABORATION_SERVER=$server_url"
        -e "GIT_USER_NAME=Claude ${instance_name^}"
        -e "GIT_USER_EMAIL=claude-${instance_name}@automation.local"
    )
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        env_args+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
    fi
    
    # Volume mounts
    local volumes=(
        -v "$CONFIG_VOLUME:/home/claude/.claude"
        -v "$project_path:/workspace"
        -v "$workspace_dir:/collaboration"
        -v "$HOME/.claude.json:/tmp/host-claude.json:ro"
        -v "$HOME/.gitconfig:/tmp/.gitconfig:ro"
    )
    
    # Install Node.js in the container and setup collaboration
    local collab_setup="
        # Install Node.js
        sudo apt-get update -qq && sudo apt-get install -y -qq nodejs npm curl
        
        # Setup collaboration client
        cd /collaboration/client
        cp claude-client.js /tmp/
        
        # Register with collaboration server
        node /tmp/claude-client.js $instance_name '$role' register
        
        echo '✅ Real-time collaboration ready for $instance_name'
    "
    
    # Create enhanced collaborative prompt
    local realtime_prompt="You are Claude Instance $instance_name in a REAL-TIME collaborative environment.

REAL-TIME COLLABORATION FEATURES:
- Instance: $instance_name
- Role: $role  
- Server: $server_url
- Real-time messaging with other Claude instances
- Shared state management
- File sharing capabilities

COLLABORATION COMMANDS (use these in your responses):
1. **Send Message**: Use \`collaborate:send:instanceName:messageType:content\`
2. **Check Messages**: Use \`collaborate:check\`
3. **Share File**: Use \`collaborate:share:filename\`
4. **Update Status**: Use \`collaborate:status:your_current_task\`

TASK DESCRIPTION:
$task_description

REAL-TIME WORKFLOW:
1. Register with collaboration server
2. Check for messages from other instances
3. Work on your assigned task
4. Send updates and questions in real-time
5. Respond to messages from other instances
6. Share relevant files and findings
7. Coordinate with other instances on complex problems

COMMUNICATION EXAMPLES:
- Ask a question: \`collaborate:send:bob:question:What authentication pattern are you seeing in the frontend?\`
- Share finding: \`collaborate:send:all:finding:Found critical security issue in API endpoint\`
- Request help: \`collaborate:send:all:help:Need assistance with database schema analysis\`

The collaboration server provides real-time communication, so you can have back-and-forth discussions with other Claude instances working on the same project.

Begin real-time collaborative work now!"
    
    echo ""
    realtime "Instance: $instance_name ($role)"
    realtime "Server: $server_url"
    realtime "Container: $container_name"
    echo ""
    
    # Start container with real-time collaboration
    docker run -it --rm \
        --name "$container_name" \
        --add-host=host.docker.internal:host-gateway \
        "${env_vars[@]}" \
        "${volumes[@]}" \
        -w /workspace \
        --user claude \
        "$DOCKER_IMAGE" \
        bash -c "
            echo '🌐 Setting up real-time collaboration for $instance_name...'
            $collab_setup
            
            echo ''
            echo '🚀 Starting Claude with real-time collaboration...'
            echo 'Paste this enhanced collaboration prompt:'
            echo '========================================'
            echo \"$realtime_prompt\"
            echo '========================================'
            echo ''
            
            claude --dangerously-skip-permissions
        "
}

# Quick start real-time collaboration
start_realtime_pair() {
    local project_path="$1"
    local workspace_dir="${2:-/tmp/claude-realtime-collab}"
    local port="${3:-8080}"
    
    realtime "Setting up real-time collaboration system"
    
    # Setup workspace and server
    mkdir -p "$workspace_dir"
    create_collaboration_server "$workspace_dir" "$port"
    create_claude_client "$workspace_dir"
    start_collaboration_server "$workspace_dir" "$port"
    
    echo ""
    realtime "🎯 Open dashboard: http://localhost:$port"
    echo ""
    
    # Wait for server to be ready
    sleep 5
    
    # Start first instance
    echo "Starting first Claude instance (Alice - Backend Analyst)..."
    echo "Press Enter when ready to start second instance..."
    read
    
    start_realtime_claude "alice" "$project_path" "$workspace_dir" \
        "Analyze backend architecture, APIs, and database design" \
        "Backend Architecture Analyst" "$port" &
    
    sleep 3
    
    echo "Starting second Claude instance (Bob - Frontend Specialist)..."
    start_realtime_claude "bob" "$project_path" "$workspace_dir" \
        "Analyze frontend components, UI patterns, and user flows" \
        "Frontend Integration Specialist" "$port"
}

# Help
show_help() {
    cat << 'EOF'
Claude Real-time Collaboration System

USAGE:
    ./claude-realtime-collab.sh [command] [options]

COMMANDS:
    setup <workspace> [port]     - Setup collaboration workspace and server
    start-server <workspace> [port] - Start collaboration server only
    start-pair <project> [workspace] [port] - Quick start collaborative pair
    start <instance> <project> <workspace> <task> <role> [port] - Start instance
    help                        - Show this help

EXAMPLES:
    # Quick start (recommended)
    ./claude-realtime-collab.sh start-pair /path/to/project

    # Manual setup
    ./claude-realtime-collab.sh setup /tmp/collab 8080
    ./claude-realtime-collab.sh start alice /path/to/project /tmp/collab \
        "Backend analysis" "Backend Specialist" 8080

FEATURES:
    🌐 Real-time messaging between Claude instances
    📊 Web dashboard for monitoring collaboration
    🔄 Shared state management
    📁 File sharing capabilities
    💬 Structured communication protocols
    📈 Activity monitoring and logging

COLLABORATION COMMANDS:
    collaborate:send:target:type:content  - Send message
    collaborate:check                     - Check for new messages
    collaborate:share:filename            - Share file
    collaborate:status:task               - Update current task

DASHBOARD:
    http://localhost:8080 (or specified port)
    - View active instances
    - Monitor real-time communication
    - Track collaboration status

This system enables true real-time collaboration between multiple Claude
instances working on the same project with immediate communication.
EOF
}

# Main function
case "${1:-help}" in
    "setup")
        workspace_dir="${2:-/tmp/claude-realtime-collab}"
        port="${3:-8080}"
        mkdir -p "$workspace_dir"
        create_collaboration_server "$workspace_dir" "$port"
        create_claude_client "$workspace_dir"
        log "Setup complete. Start server with: $0 start-server $workspace_dir $port"
        ;;
    "start-server")
        start_collaboration_server "${2:-/tmp/claude-realtime-collab}" "${3:-8080}"
        ;;
    "start-pair")
        start_realtime_pair "${2:-$(pwd)}" "${3:-/tmp/claude-realtime-collab}" "${4:-8080}"
        ;;
    "start")
        start_realtime_claude "${2:-alice}" "${3:-$(pwd)}" "${4:-/tmp/claude-realtime-collab}" \
            "${5:-Analyze the codebase}" "${6:-Code Analyst}" "${7:-8080}"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        show_help
        ;;
esac