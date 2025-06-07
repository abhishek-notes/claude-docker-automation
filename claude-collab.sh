#!/bin/bash

# Claude Collaboration System
# Creates two persistent Claude instances that can collaborate
# Follows the same pattern as claude-auto.sh with persistent memory

set -euo pipefail

DOCKER_IMAGE="claude-automation:latest"
CONFIG_VOLUME="claude-code-config"
CONTAINER_PREFIX="claude-collab"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }

# Setup persistent volumes
setup_persistent_volumes() {
    local volumes=("claude-code-config" "claude-collab-shared" "claude-alice-memory" "claude-bob-memory")
    
    for volume in "${volumes[@]}"; do
        if ! docker volume inspect "$volume" >/dev/null 2>&1; then
            log "Creating persistent volume: $volume"
            docker volume create "$volume"
        else
            log "Using existing volume: $volume"
        fi
    done
}

# Create collaboration workspace
setup_collaboration_workspace() {
    local project_path="$1"
    local collab_dir="$project_path/collaboration"
    
    log "Setting up collaboration workspace: $collab_dir"
    
    mkdir -p "$collab_dir"/{messages,status,shared,outputs,tasks}
    
    # Initialize message files
    touch "$collab_dir/messages/alice-inbox.md"
    touch "$collab_dir/messages/alice-outbox.md"
    touch "$collab_dir/messages/bob-inbox.md"
    touch "$collab_dir/messages/bob-outbox.md"
    
    # Initialize work outputs
    echo "# Alice's Work Log - $(date)" > "$collab_dir/outputs/alice-work.md"
    echo "# Bob's Work Log - $(date)" > "$collab_dir/outputs/bob-work.md"
    
    # Initialize status files
    cat > "$collab_dir/status/alice-status.json" << EOF
{
  "status": "initializing",
  "lastSeen": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "currentTask": "Starting collaboration system",
  "progress": "0%",
  "instance": "alice",
  "role": "primary-developer",
  "specialty": "backend,architecture"
}
EOF
    
    cat > "$collab_dir/status/bob-status.json" << EOF
{
  "status": "initializing", 
  "lastSeen": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "currentTask": "Starting collaboration system",
  "progress": "0%",
  "instance": "bob",
  "role": "secondary-developer",
  "specialty": "frontend,testing"
}
EOF
    
    log "✅ Collaboration workspace created at: $collab_dir"
}

# Generate collaboration prompt for Claude instances
generate_collaboration_prompt() {
    local instance="$1"
    local role="$2"
    local specialty="$3"
    local project_path="$4"
    local task_description="$5"
    
    local partner_instance
    if [ "$instance" = "alice" ]; then
        partner_instance="bob"
    else
        partner_instance="alice"
    fi
    
    cat << EOF
You are Claude instance '$instance' in a collaborative development environment.

YOUR IDENTITY:
- Instance Name: $instance
- Role: $role  
- Specialty: $specialty
- Partner: $partner_instance

COLLABORATION SYSTEM:
- Your inbox: /workspace/collaboration/messages/${instance}-inbox.md
- Your outbox: /workspace/collaboration/messages/${instance}-outbox.md
- Your work log: /workspace/collaboration/outputs/${instance}-work.md
- Your status file: /workspace/collaboration/status/${instance}-status.json
- Shared workspace: /workspace/collaboration/shared/
- Task assignments: /workspace/collaboration/tasks/

PRIMARY TASK:
$task_description

COLLABORATION PROTOCOL:
1. Check your inbox regularly for messages from your partner
2. Update your status file with current progress
3. Log all work in your work log file
4. Send updates and questions to your partner's inbox
5. Share files in the shared workspace

MESSAGE FORMAT (when writing to partner's inbox):
## Message from $instance - [timestamp]
**Type**: [update|question|request|share|status]
**Priority**: [high|medium|low]
**Content**: [your message]
**Files**: [any shared files]
**RequiresResponse**: [true|false]

STATUS UPDATE COMMANDS:
- Update status: echo '{"status":"active","lastSeen":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")","currentTask":"Your current task","progress":"50%","instance":"$instance","role":"$role","specialty":"$specialty"}' > /workspace/collaboration/status/${instance}-status.json

COLLABORATION COMMANDS:
- Check inbox: cat /workspace/collaboration/messages/${instance}-inbox.md
- Send message: echo "[message]" >> /workspace/collaboration/messages/${partner_instance}-inbox.md
- Log work: echo "[work update]" >> /workspace/collaboration/outputs/${instance}-work.md
- Share file: cp [file] /workspace/collaboration/shared/
- List shared files: ls -la /workspace/collaboration/shared/

STARTUP SEQUENCE:
1. Update your status to "active"
2. Check your inbox for any existing messages
3. Read the task description and understand your role
4. Coordinate with your partner to divide the work
5. Begin working on your assigned portion
6. Provide regular updates to your partner

Remember: You're working as a team. Share progress, ask for help, coordinate on complex tasks, and ensure all work is properly documented.

Start by updating your status and checking for messages!
EOF
}

# Start a Claude collaboration instance
start_collab_instance() {
    local instance="$1"
    local role="$2"
    local specialty="$3"
    local project_path="$4"
    local task_description="$5"
    local session_id="$6"
    
    local container_name="${CONTAINER_PREFIX}-${instance}-${session_id}"
    local prompt=$(generate_collaboration_prompt "$instance" "$role" "$specialty" "$project_path" "$task_description")
    
    log "Starting $instance instance: $container_name"
    
    # Start container with persistent memory
    docker run -d \
        --name "$container_name" \
        --hostname "claude-$instance" \
        -v "$project_path:/workspace" \
        -v "claude-code-config:/home/claude/.config/claude" \
        -v "claude-collab-shared:/collab-shared" \
        -v "claude-${instance}-memory:/claude-memory" \
        -w /workspace \
        -e "CLAUDE_INSTANCE=$instance" \
        -e "CLAUDE_ROLE=$role" \
        -e "CLAUDE_SPECIALTY=$specialty" \
        -e "COLLABORATION_ENABLED=true" \
        "$DOCKER_IMAGE" \
        bash -c "tail -f /dev/null"
    
    # Wait for container to be ready
    sleep 2
    
    # Inject the collaboration prompt
    echo "$prompt" | docker exec -i "$container_name" claude --dangerously-skip-permissions
    
    log "✅ $instance instance started successfully"
    return 0
}

# Monitor collaboration session
monitor_collaboration() {
    local project_path="$1"
    local session_id="$2"
    
    log "Starting collaboration monitoring..."
    
    # Create tmux session for monitoring
    local session_name="claude-collab-$session_id"
    
    if tmux has-session -t "$session_name" 2>/dev/null; then
        log "Attaching to existing monitoring session"
        tmux attach-session -t "$session_name"
        return 0
    fi
    
    # Start new tmux session
    tmux new-session -d -s "$session_name" -c "$project_path"
    
    # Window 1: Alice terminal
    tmux rename-window -t "$session_name:0" "Alice"
    tmux send-keys -t "$session_name:Alice" "docker exec -it claude-collab-alice-$session_id bash" Enter
    
    # Window 2: Bob terminal  
    tmux new-window -t "$session_name" -n "Bob" -c "$project_path"
    tmux send-keys -t "$session_name:Bob" "docker exec -it claude-collab-bob-$session_id bash" Enter
    
    # Window 3: Messages monitoring
    tmux new-window -t "$session_name" -n "Messages" -c "$project_path"
    tmux send-keys -t "$session_name:Messages" "watch -n 2 'echo \"=== MESSAGES ===\" && find collaboration/messages -name \"*.md\" -exec echo \"{}:\" \\; -exec tail -5 {} \\; -exec echo \\;'" Enter
    
    # Window 4: Status monitoring
    tmux new-window -t "$session_name" -n "Status" -c "$project_path"
    tmux send-keys -t "$session_name:Status" "watch -n 3 'echo \"=== STATUS ===\" && cat collaboration/status/*.json | jq . && echo && echo \"=== RECENT ACTIVITY ===\" && find collaboration -name \"*.md\" -mmin -5 -exec ls -la {} \\;'" Enter
    
    # Split status window to show work outputs
    tmux split-window -h -t "$session_name:Status"
    tmux send-keys -t "$session_name:Status.1" "watch -n 5 'echo \"=== ALICE WORK LOG ===\" && tail -10 collaboration/outputs/alice-work.md && echo && echo \"=== BOB WORK LOG ===\" && tail -10 collaboration/outputs/bob-work.md'" Enter
    
    # Go back to Alice window
    tmux select-window -t "$session_name:Alice"
    
    # Attach to session
    tmux attach-session -t "$session_name"
}

# Send message to Claude instance
send_message() {
    local instance="$1"
    local message="$2"
    local project_path="${3:-$(pwd)}"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local message_id="msg-$(date +%s)-$$"
    
    local message_text="
## Message from user - $timestamp
**ID**: $message_id
**Type**: task
**Priority**: high
**Content**: $message
**RequiresResponse**: true

---
"
    
    echo "$message_text" >> "$project_path/collaboration/messages/${instance}-inbox.md"
    log "✅ Message sent to $instance: $message"
}

# Main function
main() {
    local action="${1:-help}"
    local project_path="${2:-$(pwd)}"
    local task_description="${3:-}"
    
    case "$action" in
        "start")
            if [ -z "$task_description" ]; then
                echo -e "${RED}Error:${NC} Task description required"
                echo "Usage: $0 start <project_path> \"<task_description>\""
                exit 1
            fi
            
            local session_id="$(date +%Y%m%d-%H%M%S)"
            
            log "Starting Claude collaboration session: $session_id"
            log "Project path: $project_path"
            log "Task: $task_description"
            
            setup_persistent_volumes
            setup_collaboration_workspace "$project_path"
            
            # Start both instances
            start_collab_instance "alice" "Primary Developer" "backend,architecture" "$project_path" "$task_description" "$session_id" &
            start_collab_instance "bob" "Secondary Developer" "frontend,testing" "$project_path" "$task_description" "$session_id" &
            
            wait
            
            log "✅ Collaboration session started successfully!"
            echo
            echo "Monitor collaboration with:"
            echo "  $0 monitor $project_path $session_id"
            echo
            echo "Send messages with:"
            echo "  $0 message alice \"Your message\" $project_path"
            echo "  $0 message bob \"Your message\" $project_path"
            echo
            echo "Session ID: $session_id"
            ;;
            
        "monitor")
            local session_id="${3:-$(ls -t /workspace/collaboration/status/ 2>/dev/null | head -1 | sed 's/-.*//' | tail -1)}"
            if [ -z "$session_id" ]; then
                echo -e "${RED}Error:${NC} No active sessions found"
                exit 1
            fi
            monitor_collaboration "$project_path" "$session_id"
            ;;
            
        "message")
            local instance="$2"
            local message="$3"
            local proj_path="${4:-$(pwd)}"
            
            if [ -z "$instance" ] || [ -z "$message" ]; then
                echo -e "${RED}Error:${NC} Instance and message required"
                echo "Usage: $0 message <alice|bob> \"<message>\" [project_path]"
                exit 1
            fi
            
            send_message "$instance" "$message" "$proj_path"
            ;;
            
        "status")
            local proj_path="${2:-$(pwd)}"
            echo "=== Collaboration Status ==="
            if [ -f "$proj_path/collaboration/status/alice-status.json" ]; then
                echo "Alice:" 
                cat "$proj_path/collaboration/status/alice-status.json" | jq .
            fi
            if [ -f "$proj_path/collaboration/status/bob-status.json" ]; then
                echo "Bob:"
                cat "$proj_path/collaboration/status/bob-status.json" | jq .
            fi
            ;;
            
        "stop")
            local session_id="${2:-}"
            if [ -z "$session_id" ]; then
                echo "Stopping all collaboration containers..."
                docker ps -q --filter "name=claude-collab-" | xargs -r docker stop
                docker ps -aq --filter "name=claude-collab-" | xargs -r docker rm
            else
                echo "Stopping session: $session_id"
                docker stop "claude-collab-alice-$session_id" "claude-collab-bob-$session_id" || true
                docker rm "claude-collab-alice-$session_id" "claude-collab-bob-$session_id" || true
            fi
            ;;
            
        "help"|*)
            cat << EOF
Claude Collaboration System

Usage:
  $0 start <project_path> "<task_description>"     # Start collaboration session
  $0 monitor [project_path] [session_id]           # Monitor active session
  $0 message <alice|bob> "<message>" [project_path]  # Send message to instance
  $0 status [project_path]                         # Show collaboration status
  $0 stop [session_id]                             # Stop collaboration session

Examples:
  $0 start /Users/abhishek/Work/my-project "Analyze and improve the authentication system"
  $0 message alice "Please focus on the backend API security"
  $0 monitor /Users/abhishek/Work/my-project
  $0 status /Users/abhishek/Work/my-project

Features:
  ✅ Persistent memory across sessions
  ✅ File-based communication between instances
  ✅ Real-time monitoring with tmux
  ✅ Status tracking and work logs
  ✅ Shared workspace for collaboration
EOF
            ;;
    esac
}

# Run main function with all arguments
main "$@"