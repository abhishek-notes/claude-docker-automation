#!/bin/bash

# Claude Collaborative System - Multi-Instance Communication
# Enables multiple Claude instances to collaborate on complex tasks

set -euo pipefail

DOCKER_IMAGE="claude-automation:latest"
CONFIG_VOLUME="claude-code-config"
SHARED_WORKSPACE="/tmp/claude-collaboration"
CONTAINER_PREFIX="claude-collab"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
collab() { echo -e "${PURPLE}[COLLAB]${NC} $1"; }

# Create shared workspace
setup_shared_workspace() {
    local workspace_dir="$1"
    
    log "Setting up collaborative workspace: $workspace_dir"
    
    # Create collaboration directories
    mkdir -p "$workspace_dir"/{shared,claude-a,claude-b,communication,results}
    
    # Create communication files
    cat > "$workspace_dir/communication/README.md" << 'EOF'
# Claude Collaboration Communication Hub

## How to Collaborate

### For Claude Instance A:
1. Write your findings to `results/claude-a-findings.md`
2. Ask questions in `communication/claude-a-questions.md`
3. Read Claude B's responses from `communication/claude-b-responses.md`
4. Share code/files in `shared/` directory

### For Claude Instance B:
1. Write your findings to `results/claude-b-findings.md`
2. Ask questions in `communication/claude-b-questions.md`
3. Read Claude A's responses from `communication/claude-a-responses.md`
4. Share code/files in `shared/` directory

### Communication Protocol:
- Always check for new messages before starting work
- Update your status in `communication/status.md`
- Use clear, specific questions
- Reference files and line numbers when discussing code

### File Naming Convention:
- Questions: `claude-{a|b}-questions-{timestamp}.md`
- Responses: `claude-{a|b}-responses-{timestamp}.md`
- Findings: `claude-{a|b}-findings-{topic}.md`
- Shared code: `shared/{descriptive-name}.{ext}`
EOF
    
    # Create initial status file
    cat > "$workspace_dir/communication/status.md" << 'EOF'
# Collaboration Status

## Claude Instance A
- Status: Not Started
- Current Task: 
- Last Update: 
- Questions Pending: 0

## Claude Instance B
- Status: Not Started
- Current Task: 
- Last Update: 
- Questions Pending: 0

## Shared Resources
- Files: 0
- Active Discussions: 0
- Completed Tasks: 0
EOF
    
    # Create template files
    touch "$workspace_dir/communication/claude-a-questions.md"
    touch "$workspace_dir/communication/claude-b-questions.md"
    touch "$workspace_dir/communication/claude-a-responses.md"
    touch "$workspace_dir/communication/claude-b-responses.md"
    
    log "✅ Shared workspace ready at: $workspace_dir"
}

# Start collaborative Claude instance
start_claude_instance() {
    local instance_name="$1"
    local project_path="$2"
    local collaboration_workspace="$3"
    local task_description="$4"
    local instance_role="$5"
    
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${instance_name}-${session_id}"
    
    log "Starting Claude instance: $instance_name"
    
    # Environment variables
    local env_vars=(
        -e "CLAUDE_CONFIG_DIR=/home/claude/.claude"
        -e "CLAUDE_INSTANCE_NAME=$instance_name"
        -e "CLAUDE_INSTANCE_ROLE=$instance_role"
        -e "GIT_USER_NAME=Claude ${instance_name^}"
        -e "GIT_USER_EMAIL=claude-${instance_name}@automation.local"
    )
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        env_vars+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
    fi
    
    # Volume mounts
    local volumes=(
        -v "$CONFIG_VOLUME:/home/claude/.claude"
        -v "$project_path:/workspace"
        -v "$collaboration_workspace:/collaboration"
        -v "$HOME/.claude.json:/tmp/host-claude.json:ro"
        -v "$HOME/.gitconfig:/tmp/.gitconfig:ro"
    )
    
    # Create collaborative task prompt
    local collab_prompt="You are Claude Instance $instance_name working in a collaborative environment with other Claude instances.

COLLABORATION SETUP:
- Your role: $instance_role
- Collaboration workspace: /collaboration
- Communication hub: /collaboration/communication/
- Shared files: /collaboration/shared/
- Your results: /collaboration/results/claude-${instance_name}-findings.md

COLLABORATION PROTOCOL:
1. **Always check for messages first**: Read /collaboration/communication/claude-${instance_name}-questions.md for questions directed to you
2. **Update your status**: Update /collaboration/communication/status.md with your current task
3. **Ask questions when needed**: Write to /collaboration/communication/claude-${instance_name}-questions.md
4. **Share findings**: Document everything in /collaboration/results/claude-${instance_name}-findings.md
5. **Respond to questions**: Check other instance's questions and respond in appropriate files

TASK DESCRIPTION:
$task_description

WORKING INSTRUCTIONS:
1. Start by reading the collaboration README at /collaboration/communication/README.md
2. Check for any existing questions or messages
3. Update your status to 'Working on: [task description]'
4. Work on your assigned task systematically
5. Document findings and share relevant files
6. Ask questions when you need clarification from the other instance
7. Create a feature branch: claude/${instance_name}/session-$session_id

COMMUNICATION EXAMPLE:
To ask a question, write to /collaboration/communication/claude-${instance_name}-questions.md:
'''
## Question $(date '+%Y-%m-%d %H:%M:%S')
**Topic**: API Integration
**Question**: I found an unusual pattern in the authentication flow at line 45 of api/auth.ts. Can you verify if this is intentional or if there's a better approach?
**Context**: [Provide relevant context]
**Files**: /workspace/src/api/auth.ts:45
'''

Begin collaboration now!"
    
    echo ""
    collab "Starting collaborative Claude instance: $instance_name"
    echo -e "${BLUE}Role: $instance_role${NC}"
    echo -e "${BLUE}Task: $task_description${NC}"
    echo -e "${BLUE}Container: $container_name${NC}"
    echo ""
    
    # Start in background or foreground based on preference
    if [ "${BACKGROUND:-false}" = "true" ]; then
        docker run -d \
            --name "$container_name" \
            "${env_vars[@]}" \
            "${volumes[@]}" \
            -w /workspace \
            --user claude \
            "$DOCKER_IMAGE" \
            bash -c "
                echo '🤝 Starting collaborative Claude instance: $instance_name'
                echo 'Role: $instance_role'
                echo ''
                
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
                
                echo '🚀 Starting Claude with collaboration protocol...'
                
                # Auto-start with collaboration prompt
                echo \"$collab_prompt\" | claude --dangerously-skip-permissions
            "
        
        info "Instance $instance_name started in background. Container: $container_name"
        info "Attach with: docker attach $container_name"
    else
        # Interactive mode
        docker run -it --rm \
            --name "$container_name" \
            "${env_vars[@]}" \
            "${volumes[@]}" \
            -w /workspace \
            --user claude \
            "$DOCKER_IMAGE" \
            bash -c "
                echo '🤝 Starting collaborative Claude instance: $instance_name'
                echo 'Role: $instance_role'
                echo ''
                
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
                
                echo '🚀 Starting Claude Code...'
                echo 'Paste this collaboration prompt:'
                echo '================================'
                echo \"$collab_prompt\"
                echo '================================'
                echo ''
                
                claude --dangerously-skip-permissions
            "
    fi
}

# Monitor collaboration
monitor_collaboration() {
    local workspace_dir="$1"
    
    collab "Monitoring collaboration workspace: $workspace_dir"
    
    while true; do
        clear
        echo -e "${PURPLE}Claude Collaboration Monitor${NC}"
        echo "================================"
        echo ""
        
        # Show status
        if [ -f "$workspace_dir/communication/status.md" ]; then
            echo -e "${BLUE}Current Status:${NC}"
            cat "$workspace_dir/communication/status.md"
            echo ""
        fi
        
        # Show recent activity
        echo -e "${BLUE}Recent Activity:${NC}"
        find "$workspace_dir" -name "*.md" -newer "$workspace_dir/communication/README.md" 2>/dev/null | head -5 | while read file; do
            echo "📝 $(basename "$file") - $(stat -f %Sm "$file")"
        done
        
        echo ""
        echo -e "${BLUE}Communication Files:${NC}"
        ls -la "$workspace_dir/communication/" | grep -E "\\.md$" | while read line; do
            echo "💬 $line"
        done
        
        echo ""
        echo -e "${BLUE}Shared Files:${NC}"
        ls -la "$workspace_dir/shared/" 2>/dev/null | head -10 | while read line; do
            echo "🔄 $line"
        done
        
        echo ""
        echo "Press Ctrl+C to exit monitoring"
        sleep 10
    done
}

# Show active collaboration
show_collaboration_status() {
    local workspace_dir="${1:-$SHARED_WORKSPACE}"
    
    if [ ! -d "$workspace_dir" ]; then
        warn "No collaboration workspace found at: $workspace_dir"
        return 1
    fi
    
    echo -e "${PURPLE}Collaboration Status Report${NC}"
    echo "================================"
    echo ""
    
    # Show running containers
    echo -e "${BLUE}Active Claude Instances:${NC}"
    docker ps --filter name=claude-collab --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    # Show workspace contents
    echo -e "${BLUE}Workspace Contents:${NC}"
    tree "$workspace_dir" 2>/dev/null || find "$workspace_dir" -type f | head -20
    echo ""
    
    # Show recent communications
    echo -e "${BLUE}Recent Communications:${NC}"
    find "$workspace_dir/communication" -name "*.md" -exec basename {} \; 2>/dev/null | sort
}

# Cleanup collaboration
cleanup_collaboration() {
    local workspace_dir="${1:-$SHARED_WORKSPACE}"
    
    warn "Stopping all collaborative Claude instances..."
    docker ps --filter name=claude-collab -q | xargs -r docker stop
    
    if [ "$workspace_dir" != "/" ] && [ -d "$workspace_dir" ]; then
        read -p "Remove collaboration workspace at $workspace_dir? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$workspace_dir"
            log "Collaboration workspace removed"
        fi
    fi
}

# Help
show_help() {
    cat << 'EOF'
Claude Collaborative System - Multi-Instance Communication

USAGE:
    ./claude-collaborative.sh [command] [options]

COMMANDS:
    setup <workspace>           - Setup collaboration workspace
    start-pair <project> <workspace>  - Start two collaborative instances
    start <instance> <project> <workspace> <task> <role>  - Start single instance
    monitor <workspace>         - Monitor collaboration activity
    status [workspace]          - Show collaboration status
    cleanup [workspace]         - Stop instances and cleanup
    help                       - Show this help

EXAMPLES:
    # Setup and start collaborative pair
    ./claude-collaborative.sh setup /tmp/claude-collab
    ./claude-collaborative.sh start-pair /path/to/project /tmp/claude-collab

    # Start individual instances
    ./claude-collaborative.sh start alice /path/to/project /tmp/claude-collab \
        "Analyze backend architecture" "Backend Specialist"
    ./claude-collaborative.sh start bob /path/to/project /tmp/claude-collab \
        "Analyze frontend components" "Frontend Specialist"

    # Monitor and manage
    ./claude-collaborative.sh monitor /tmp/claude-collab
    ./claude-collaborative.sh status
    ./claude-collaborative.sh cleanup

COLLABORATION FEATURES:
    ✅ File-based communication between instances
    ✅ Shared workspace for code and resources
    ✅ Real-time status monitoring
    ✅ Structured question/answer protocol
    ✅ Independent git branches per instance
    ✅ Background or interactive execution

COMMUNICATION PROTOCOL:
    - Instances communicate via markdown files
    - Questions and responses are timestamped
    - Shared code repository for collaboration
    - Status tracking for coordination

The system enables complex multi-angle analysis where each Claude instance
can focus on different aspects while maintaining communication.
EOF
}

# Quick start - setup and launch pair
start_collaborative_pair() {
    local project_path="$1"
    local workspace_dir="${2:-$SHARED_WORKSPACE}"
    
    # Setup workspace
    setup_shared_workspace "$workspace_dir"
    
    echo ""
    collab "Starting collaborative Claude pair"
    echo -e "${BLUE}Project: $project_path${NC}"
    echo -e "${BLUE}Workspace: $workspace_dir${NC}"
    echo ""
    
    # Start first instance in background
    BACKGROUND=true start_claude_instance "alice" "$project_path" "$workspace_dir" \
        "Analyze system architecture, backend components, and data flow" \
        "System Architecture Analyst"
    
    sleep 2
    
    # Start second instance in background  
    BACKGROUND=true start_claude_instance "bob" "$project_path" "$workspace_dir" \
        "Analyze frontend components, user interfaces, and integration patterns" \
        "Frontend Integration Specialist"
    
    echo ""
    collab "Both instances started! Use these commands to interact:"
    echo ""
    echo "# Attach to Alice (Architecture Analyst)"
    echo "docker attach claude-collab-alice-$(date +%Y%m%d-%H%M%S)"
    echo ""
    echo "# Attach to Bob (Frontend Specialist)"  
    echo "docker attach claude-collab-bob-$(date +%Y%m%d-%H%M%S)"
    echo ""
    echo "# Monitor collaboration"
    echo "./claude-collaborative.sh monitor $workspace_dir"
    echo ""
    echo "# Check status"
    echo "./claude-collaborative.sh status $workspace_dir"
}

# Main function
case "${1:-help}" in
    "setup")
        setup_shared_workspace "${2:-$SHARED_WORKSPACE}"
        ;;
    "start-pair")
        start_collaborative_pair "${2:-$(pwd)}" "${3:-$SHARED_WORKSPACE}"
        ;;
    "start")
        start_claude_instance "${2:-alice}" "${3:-$(pwd)}" "${4:-$SHARED_WORKSPACE}" \
            "${5:-Analyze the codebase}" "${6:-Code Analyst}"
        ;;
    "monitor")
        monitor_collaboration "${2:-$SHARED_WORKSPACE}"
        ;;
    "status")
        show_collaboration_status "${2:-$SHARED_WORKSPACE}"
        ;;
    "cleanup")
        cleanup_collaboration "${2:-$SHARED_WORKSPACE}"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        show_help
        ;;
esac