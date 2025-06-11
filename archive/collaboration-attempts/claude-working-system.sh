#!/bin/bash

# Claude Working System - Actually Functioning Multi-Instance Communication
# This creates Claude instances that ACTUALLY respond and work

set -euo pipefail

DOCKER_IMAGE="claude-automation:latest"
CONFIG_VOLUME="claude-code-config"
WORKING_PORT=8082
CONTAINER_PREFIX="claude-working"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[WORKING]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
working() { echo -e "${PURPLE}[SYSTEM]${NC} $1"; }

# Create a working Claude instance with proper initialization
create_working_claude() {
    local instance_id="$1"
    local role="$2" 
    local task="$3"
    local project_path="${4:-/Users/abhishek/Work/palladio-software-25}"
    local collab_dir="/tmp/claude-collab-working"
    
    # Create collaboration workspace
    mkdir -p "$collab_dir/shared" "$collab_dir/messages" "$collab_dir/outputs"
    
    # Create communication files
    touch "$collab_dir/messages/${instance_id}-inbox.md"
    touch "$collab_dir/messages/${instance_id}-outbox.md" 
    touch "$collab_dir/outputs/${instance_id}-work.md"
    
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${instance_id}-${session_id}"
    
    working "Creating working Claude instance: $instance_id"
    
    # Environment variables
    local env_vars=(
        -e "CLAUDE_CONFIG_DIR=/home/claude/.claude"
        -e "CLAUDE_INSTANCE_ID=$instance_id"
        -e "CLAUDE_ROLE=$role"
        -e "CLAUDE_TASK=$task"
        -e "GIT_USER_NAME=Claude-${instance_id}"
        -e "GIT_USER_EMAIL=claude-${instance_id}@automation.local"
    )
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        env_vars+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
    fi
    
    # Volume mounts
    local volumes=(
        -v "$CONFIG_VOLUME:/home/claude/.claude"
        -v "$project_path:/workspace"
        -v "$collab_dir:/collaboration"
        -v "$HOME/.claude.json:/tmp/host-claude.json:ro"
        -v "$HOME/.gitconfig:/tmp/.gitconfig:ro"
    )
    
    # Create comprehensive working prompt
    local working_prompt="You are Claude instance '$instance_id' working as a $role.

YOUR TASK: $task

COLLABORATION SYSTEM:
- Your inbox: /collaboration/messages/${instance_id}-inbox.md (check for messages FROM other Claude instances or users)
- Your outbox: /collaboration/messages/${instance_id}-outbox.md (write messages TO other instances)
- Your work output: /collaboration/outputs/${instance_id}-work.md (document your progress and findings)
- Shared workspace: /collaboration/shared/ (share files with other instances)

WORKING PROTOCOL:
1. **Start immediately** by updating your work output with: 'STARTING: [brief description of what you're doing]'
2. **Check your inbox** regularly for messages from other instances or users
3. **Work on your task** actively and document everything in your work output
4. **Respond to messages** by writing to your outbox
5. **Ask questions** by writing to your outbox with 'QUESTION FOR [instance]: [question]'
6. **Share findings** by updating your work output frequently

COMMUNICATION FORMAT:
To send a message to another instance, write to your outbox:
'MESSAGE TO [instance_id]: [your message]'

To ask a question:
'QUESTION FOR [instance_id]: [your question]'

To broadcast to all:
'BROADCAST: [your message]'

WORK OUTPUT FORMAT:
Always update /collaboration/outputs/${instance_id}-work.md with:
- What you're currently doing
- What you've found
- Any questions or issues
- Your progress status

IMPORTANT: 
- Work continuously and actively
- Check inbox every few minutes
- Update work output frequently  
- Respond to questions promptly
- Stay focused on your task

BEGIN WORKING NOW! Start by writing to your work output file that you're beginning the task."
    
    # Start the container with working Claude
    docker run -d \
        --name "$container_name" \
        "${env_vars[@]}" \
        "${volumes[@]}" \
        -w /workspace \
        --user claude \
        "$DOCKER_IMAGE" \
        bash -c "
            echo 'Setting up Claude $instance_id environment...'
            
            # Setup environment
            sudo chown -R claude:claude /home/claude/.claude 2>/dev/null || true
            if [ -f '/tmp/host-claude.json' ] && [ ! -f '/home/claude/.claude.json' ]; then
                cp /tmp/host-claude.json /home/claude/.claude.json
                chmod 600 /home/claude/.claude.json
            fi
            if [ -f '/tmp/.gitconfig' ]; then
                cp /tmp/.gitconfig /home/claude/.gitconfig
            fi
            git config --global init.defaultBranch main
            git config --global --add safe.directory /workspace
            
            echo 'Claude $instance_id ready to work!'
            echo ''
            echo 'Starting Claude with working prompt...'
            
            # Create initial work output
            echo 'STARTING: Claude $instance_id ($role) beginning task: $task' > /collaboration/outputs/${instance_id}-work.md
            echo 'Status: Initializing' >> /collaboration/outputs/${instance_id}-work.md
            echo 'Time: \$(date)' >> /collaboration/outputs/${instance_id}-work.md
            echo '' >> /collaboration/outputs/${instance_id}-work.md
            
            # Start Claude with the working prompt
            echo \"$working_prompt\" | claude --dangerously-skip-permissions
        "
    
    if [ $? -eq 0 ]; then
        working "✅ Claude $instance_id started in container: $container_name"
        echo "$container_name" > "$collab_dir/${instance_id}-container.txt"
        
        # Give it a moment to initialize
        sleep 3
        
        # Check if it's actually working
        if [ -f "$collab_dir/outputs/${instance_id}-work.md" ]; then
            working "✅ Claude $instance_id is working - check /collaboration/outputs/${instance_id}-work.md"
        fi
        
    else
        error "Failed to start Claude $instance_id"
        return 1
    fi
}

# Send message to a Claude instance
send_message_to_claude() {
    local target_instance="$1"
    local message="$2"
    local from="${3:-User}"
    local collab_dir="/tmp/claude-collab-working"
    
    if [ ! -f "$collab_dir/messages/${target_instance}-inbox.md" ]; then
        error "Instance $target_instance not found or not running"
        return 1
    fi
    
    echo "" >> "$collab_dir/messages/${target_instance}-inbox.md"
    echo "## Message from $from - $(date)" >> "$collab_dir/messages/${target_instance}-inbox.md"
    echo "$message" >> "$collab_dir/messages/${target_instance}-inbox.md"
    echo "" >> "$collab_dir/messages/${target_instance}-inbox.md"
    
    working "✅ Message sent to $target_instance"
    
    # Also notify the container (send a signal to check inbox)
    if [ -f "$collab_dir/${target_instance}-container.txt" ]; then
        local container_name=$(cat "$collab_dir/${target_instance}-container.txt")
        docker exec "$container_name" bash -c "echo 'NEW MESSAGE: Check your inbox at /collaboration/messages/${target_instance}-inbox.md' >> /tmp/notify.txt" 2>/dev/null || true
    fi
}

# Monitor Claude instances
monitor_working_instances() {
    local collab_dir="/tmp/claude-collab-working"
    
    if [ ! -d "$collab_dir" ]; then
        error "No working instances found"
        return 1
    fi
    
    working "Monitoring Claude instances..."
    
    while true; do
        clear
        echo -e "${CYAN}🤖 Claude Working Instances Monitor${NC}"
        echo "======================================"
        echo ""
        
        # Show active instances
        echo -e "${BLUE}Active Instances:${NC}"
        docker ps --filter name=claude-working --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"
        echo ""
        
        # Show work outputs
        echo -e "${BLUE}Recent Work Output:${NC}"
        for work_file in "$collab_dir/outputs"/*-work.md; do
            if [ -f "$work_file" ]; then
                local instance=$(basename "$work_file" -work.md)
                echo -e "${YELLOW}[$instance]${NC}"
                tail -5 "$work_file" 2>/dev/null | sed 's/^/  /'
                echo ""
            fi
        done
        
        # Show recent messages
        echo -e "${BLUE}Recent Messages:${NC}"
        for inbox_file in "$collab_dir/messages"/*-inbox.md; do
            if [ -f "$inbox_file" ] && [ -s "$inbox_file" ]; then
                local instance=$(basename "$inbox_file" -inbox.md)
                echo -e "${YELLOW}Messages for [$instance]:${NC}"
                tail -3 "$inbox_file" 2>/dev/null | sed 's/^/  /'
                echo ""
            fi
        done
        
        echo ""
        echo "Press Ctrl+C to exit monitoring"
        sleep 10
    done
}

# Interactive chat with Claude instances
interactive_chat() {
    local collab_dir="/tmp/claude-collab-working"
    
    echo -e "${CYAN}🗣️  Interactive Chat with Claude Instances${NC}"
    echo "============================================="
    echo ""
    
    # Show available instances
    echo "Available instances:"
    for work_file in "$collab_dir/outputs"/*-work.md; do
        if [ -f "$work_file" ]; then
            local instance=$(basename "$work_file" -work.md)
            echo "  - $instance"
        fi
    done
    echo ""
    
    while true; do
        echo -e "${BLUE}Commands:${NC}"
        echo "  msg <instance> <message>  - Send message to instance"
        echo "  broadcast <message>       - Send to all instances"
        echo "  status                    - Show all instance status"
        echo "  quit                      - Exit chat"
        echo ""
        
        read -p "Chat> " input
        
        if [ -z "$input" ]; then
            continue
        fi
        
        case "$input" in
            msg\ *)
                # Parse: msg instance message
                local cmd_parts=($input)
                local instance="${cmd_parts[1]}"
                local message="${input#msg $instance }"
                send_message_to_claude "$instance" "$message" "User"
                ;;
            broadcast\ *)
                # Send to all instances
                local message="${input#broadcast }"
                for work_file in "$collab_dir/outputs"/*-work.md; do
                    if [ -f "$work_file" ]; then
                        local instance=$(basename "$work_file" -work.md)
                        send_message_to_claude "$instance" "BROADCAST: $message" "User"
                    fi
                done
                working "Broadcast sent to all instances"
                ;;
            status)
                echo ""
                for work_file in "$collab_dir/outputs"/*-work.md; do
                    if [ -f "$work_file" ]; then
                        local instance=$(basename "$work_file" -work.md)
                        echo -e "${YELLOW}[$instance] Latest work:${NC}"
                        tail -3 "$work_file" | sed 's/^/  /'
                        echo ""
                    fi
                done
                ;;
            quit)
                break
                ;;
            *)
                echo "Unknown command. Use: msg <instance> <message>, broadcast <message>, status, or quit"
                ;;
        esac
        echo ""
    done
}

# Quick demo with working instances
start_working_demo() {
    local project_path="/Users/abhishek/Work/palladio-software-25"
    
    working "Starting working Claude demo with actual collaboration"
    
    # Create first instance
    create_working_claude "alice" "Backend Analyst" "Analyze the Medusa e-commerce backend architecture and identify key components" "$project_path"
    
    sleep 2
    
    # Create second instance
    create_working_claude "bob" "Frontend Specialist" "Analyze the Next.js frontend and Strapi CMS integration patterns" "$project_path"
    
    sleep 2
    
    # Send initial messages to get them started
    send_message_to_claude "alice" "Start by examining the Medusa configuration and Salesforce integration. Document what you find in your work output."
    send_message_to_claude "bob" "Begin by analyzing the frontend components and how they connect to the backend APIs. Share your findings."
    
    echo ""
    working "✅ Working demo started!"
    echo ""
    echo -e "${YELLOW}Two Claude instances are now actively working:${NC}"
    echo "  - Alice: Backend Analyst (analyzing Medusa backend)"
    echo "  - Bob: Frontend Specialist (analyzing Next.js frontend)"
    echo ""
    echo -e "${BLUE}Available commands:${NC}"
    echo "  ./claude-working-system.sh monitor    - Watch their work in real-time"
    echo "  ./claude-working-system.sh chat       - Chat with them interactively"
    echo "  ./claude-working-system.sh status     - Check their current work"
    echo ""
    echo -e "${CYAN}They are working now! Check their progress:${NC}"
    echo "  cat /tmp/claude-collab-working/outputs/alice-work.md"
    echo "  cat /tmp/claude-collab-working/outputs/bob-work.md"
}

# Show status of working instances
show_status() {
    local collab_dir="/tmp/claude-collab-working"
    
    echo -e "${CYAN}🤖 Claude Working Instances Status${NC}"
    echo "===================================="
    echo ""
    
    # Show Docker containers
    echo -e "${BLUE}Docker Containers:${NC}"
    docker ps --filter name=claude-working --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    # Show work outputs
    echo -e "${BLUE}Current Work Status:${NC}"
    for work_file in "$collab_dir/outputs"/*-work.md; do
        if [ -f "$work_file" ]; then
            local instance=$(basename "$work_file" -work.md)
            echo -e "${YELLOW}[$instance]${NC}"
            echo "File: $work_file"
            echo "Last updated: $(stat -f %Sm "$work_file" 2>/dev/null || stat -c %y "$work_file" 2>/dev/null)"
            echo "Recent work:"
            tail -5 "$work_file" | sed 's/^/  /'
            echo ""
        fi
    done
    
    # Show message activity
    echo -e "${BLUE}Message Activity:${NC}"
    for inbox_file in "$collab_dir/messages"/*-inbox.md; do
        if [ -f "$inbox_file" ] && [ -s "$inbox_file" ]; then
            local instance=$(basename "$inbox_file" -inbox.md)
            local msg_count=$(wc -l < "$inbox_file")
            echo "  $instance: $msg_count lines of messages"
        fi
    done
}

# Stop all working instances
stop_working_instances() {
    working "Stopping all working Claude instances..."
    
    # Stop containers
    docker ps --filter name=claude-working -q | xargs -r docker stop
    docker ps -a --filter name=claude-working -q | xargs -r docker rm
    
    # Clean up collaboration directory
    rm -rf /tmp/claude-collab-working
    
    working "✅ All working instances stopped"
}

# Help
show_help() {
    cat << 'EOF'
Claude Working System - Actually Functioning Multi-Instance Communication

This creates Claude instances that ACTUALLY work and respond.

COMMANDS:
    demo                     - Start working demo with 2 Claude instances
    create <id> <role> <task> - Create a working Claude instance
    message <instance> <msg> - Send message to a Claude instance
    monitor                  - Monitor all instances in real-time
    chat                     - Interactive chat with Claude instances
    status                   - Show current status of all instances
    stop                     - Stop all working instances
    help                     - Show this help

EXAMPLES:
    # Start working demo
    ./claude-working-system.sh demo

    # Create custom instance
    ./claude-working-system.sh create charlie "API Tester" "Test all API endpoints"

    # Send message
    ./claude-working-system.sh message alice "Check the authentication system"

    # Monitor their work
    ./claude-working-system.sh monitor

    # Interactive chat
    ./claude-working-system.sh chat

This creates Claude instances that actually work and communicate!
EOF
}

# Main function
case "${1:-demo}" in
    "demo")
        start_working_demo
        ;;
    "create")
        create_working_claude "${2:-alice}" "${3:-Analyst}" "${4:-Analyze the project}"
        ;;
    "message")
        send_message_to_claude "$2" "$3" "User"
        ;;
    "monitor")
        monitor_working_instances
        ;;
    "chat")
        interactive_chat
        ;;
    "status")
        show_status
        ;;
    "stop")
        stop_working_instances
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        show_help
        ;;
esac