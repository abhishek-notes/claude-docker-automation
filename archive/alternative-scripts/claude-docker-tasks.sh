#!/bin/bash

# Claude Docker Automation System - Task Completion Version
# Runs until tasks are complete rather than time-based

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="claude-automation:latest"
CONTAINER_PREFIX="claude-session"
CONFIG_DIR="$HOME/.claude-docker"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Functions
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Ensure Docker image exists
build_image() {
    if ! docker image inspect $DOCKER_IMAGE >/dev/null 2>&1; then
        log "Building Claude automation Docker image..."
        docker build -t $DOCKER_IMAGE "$SCRIPT_DIR"
    else
        info "Docker image $DOCKER_IMAGE already exists"
    fi
}

# Initialize configuration
init_config() {
    mkdir -p "$CONFIG_DIR"
    
    if [ ! -f "$CONFIG_DIR/config.json" ]; then
        cat > "$CONFIG_DIR/config.json" << 'EOF'
{
  "defaultWorkspace": "/Users/abhishek/Work",
  "autoCommit": true,
  "autoPush": false,
  "branchPrefix": "claude/",
  "taskBased": true,
  "maxTokens": 100000
}
EOF
        info "Created default configuration at $CONFIG_DIR/config.json"
    fi
}

# Get current project info
get_project_info() {
    local project_path="$1"
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    
    echo "$project_name:$session_id"
}

# Start Claude session (task-completion based)
start_session() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    
    # Validate project path
    if [ ! -d "$project_path" ]; then
        error "Project path does not exist: $project_path"
        exit 1
    fi
    
    # Check for task file
    if [ ! -f "$project_path/$task_file" ]; then
        error "Task file not found: $project_path/$task_file"
        echo ""
        echo "Please create a task file with your requirements."
        echo "Example: CLAUDE_TASKS.md"
        exit 1
    fi
    
    # Get project info
    local project_info=$(get_project_info "$project_path")
    local project_name=$(echo "$project_info" | cut -d: -f1)
    local session_id=$(echo "$project_info" | cut -d: -f2)
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "Starting task-completion Claude session: $container_name"
    log "Project: $project_path"
    log "Task file: $task_file"
    log "Mode: Work until tasks complete"
    echo ""
    
    # Prepare environment variables
    local env_args=()
    
    # Add GitHub token if available
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        env_args+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
        info "GitHub integration enabled"
    else
        warning "No GITHUB_TOKEN set - repository operations disabled"
    fi
    
    # Check for Anthropic API key
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        env_args+=(-e "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
        info "Using API key authentication"
    else
        warning "No ANTHROPIC_API_KEY - you'll need to authenticate in container"
    fi
    
    # Add git configuration
    env_args+=(-e "GIT_USER_NAME=${GIT_USER_NAME:-Claude Automation}")
    env_args+=(-e "GIT_USER_EMAIL=${GIT_USER_EMAIL:-claude@automation.local}")
    
    # Mount configurations if they exist
    local mount_args=()
    
    # Mount git config
    if [ -f "$HOME/.gitconfig" ]; then
        mount_args+=(-v "$HOME/.gitconfig:/tmp/.gitconfig:ro")
    fi
    
    # Mount Claude config if exists (for Claude Max login)
    if [ -d "$HOME/.claude" ]; then
        mount_args+=(-v "$HOME/.claude:/tmp/.claude:ro")
    fi
    
    # Mount Claude Desktop config if exists
    local claude_desktop_config="$HOME/Library/Application Support/Claude"
    if [ -d "$claude_desktop_config" ]; then
        mount_args+=(-v "$claude_desktop_config:/tmp/claude-desktop:ro")
    fi
    
    # Create session prompt for task completion
    local session_prompt="You are starting a task-completion based autonomous work session.

Instructions:
1. Read and complete ALL tasks in $task_file
2. Work systematically through each task until completion
3. Create a feature branch: claude/session-$session_id
4. Work autonomously using --dangerously-skip-permissions (already enabled)
5. Create PROGRESS.md and update it after completing each major task
6. Commit changes frequently with meaningful messages
7. Test everything thoroughly as you build
8. Create comprehensive SUMMARY.md when ALL tasks are complete
9. Document any issues in ISSUES.md
10. Exit ONLY when all tasks are genuinely complete and working

Task Completion Criteria:
- All requirements in the task file are met
- All tests pass
- Documentation is complete
- Code is working as specified
- SUMMARY.md confirms completion

You have full permissions in this Docker environment. Work until the job is done!"
    
    info "Starting container with task-completion mode..."
    echo ""
    
    # Start container with interactive session
    docker run -it --rm \
        --name "$container_name" \
        "${env_args[@]}" \
        "${mount_args[@]}" \
        -v "$project_path:/workspace" \
        -w /workspace \
        $DOCKER_IMAGE \
        bash -c "claude --dangerously-skip-permissions -p \"$session_prompt\""
    
    log "Session completed: $container_name"
    
    # Show results
    echo ""
    echo -e "${PURPLE}📊 Task Completion Results:${NC}"
    echo "==============================="
    
    local result_files=("PROGRESS.md" "SUMMARY.md" "ISSUES.md")
    for file in "${result_files[@]}"; do
        if [ -f "$project_path/$file" ]; then
            echo -e "${GREEN}✓${NC} $file created"
        else
            echo -e "${YELLOW}⚠${NC} $file not found"
        fi
    done
    
    # Show git status if in git repo
    if [ -d "$project_path/.git" ]; then
        echo ""
        echo -e "${BLUE}📋 Git Status:${NC}"
        cd "$project_path"
        git status --short
        
        # Show recent commits
        echo ""
        echo -e "${BLUE}📝 Recent Commits:${NC}"
        git log --oneline -10 || true
        
        # Show branch info
        echo ""
        echo -e "${BLUE}🌿 Branches:${NC}"
        git branch -a | grep claude || echo "No Claude branches found"
    fi
    
    # Show summary if available
    if [ -f "$project_path/SUMMARY.md" ]; then
        echo ""
        echo -e "${PURPLE}📄 Task Summary:${NC}"
        echo "================"
        head -20 "$project_path/SUMMARY.md"
        echo ""
        echo "Full summary available in: $project_path/SUMMARY.md"
    fi
}

# List running sessions
list_sessions() {
    echo -e "${BLUE}🐳 Active Claude Sessions:${NC}"
    echo "=========================="
    
    local containers=$(docker ps --filter name="$CONTAINER_PREFIX" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")
    
    if [ -z "$containers" ] || [ "$containers" = "NAMES	STATUS	PORTS" ]; then
        echo "No active sessions found."
    else
        echo "$containers"
    fi
}

# Attach to existing session
attach_session() {
    local sessions=($(docker ps --filter name="$CONTAINER_PREFIX" --format "{{.Names}}"))
    
    if [ ${#sessions[@]} -eq 0 ]; then
        warning "No active sessions found"
        return 1
    elif [ ${#sessions[@]} -eq 1 ]; then
        local container_name="${sessions[0]}"
    else
        echo "Multiple sessions found:"
        for i in "${!sessions[@]}"; do
            echo "$((i+1)). ${sessions[i]}"
        done
        echo ""
        read -p "Select session (1-${#sessions[@]}): " choice
        
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#sessions[@]} ]; then
            error "Invalid selection"
            return 1
        fi
        
        local container_name="${sessions[$((choice-1))]}"
    fi
    
    log "Attaching to session: $container_name"
    docker exec -it "$container_name" bash
}

# Stop sessions
stop_sessions() {
    local sessions=($(docker ps --filter name="$CONTAINER_PREFIX" --format "{{.Names}}"))
    
    if [ ${#sessions[@]} -eq 0 ]; then
        warning "No active sessions found"
        return 0
    fi
    
    for container in "${sessions[@]}"; do
        log "Stopping session: $container"
        docker stop "$container" >/dev/null
    done
    
    log "All sessions stopped"
}

# Show help
show_help() {
    cat << 'EOF'
Claude Docker Automation System - Task Completion Mode

USAGE:
    ./claude-docker-tasks.sh [COMMAND] [OPTIONS]

COMMANDS:
    start [path] [task-file]     Start task-completion session
    list                         List active sessions
    attach                       Attach to existing session
    stop                         Stop all sessions
    build                        Build Docker image
    config                       Show configuration
    help                         Show this help

TASK-COMPLETION MODE:
    Claude works until ALL tasks in the task file are complete.
    No time limits - focuses on finishing the job properly.

EXAMPLES:
    ./claude-docker-tasks.sh start                    # Start in current directory
    ./claude-docker-tasks.sh start /path/to/project   # Start in specific project
    ./claude-docker-tasks.sh start . my-tasks.md      # Custom task file
    ./claude-docker-tasks.sh list                     # List running sessions
    ./claude-docker-tasks.sh attach                   # Attach to session

ENVIRONMENT VARIABLES:
    GITHUB_TOKEN        GitHub personal access token
    ANTHROPIC_API_KEY   Anthropic API key (optional with Claude Max)
    GIT_USER_NAME       Git user name for commits
    GIT_USER_EMAIL      Git user email for commits

AUTHENTICATION:
    - If you have Claude Max: Authentication will use your desktop login
    - If using API: Set ANTHROPIC_API_KEY in environment
    - GitHub: Set GITHUB_TOKEN for repository operations

TASK FILE FORMAT:
    Create a markdown file (usually CLAUDE_TASKS.md) with:
    - Clear task descriptions
    - Acceptance criteria
    - Technical requirements
    - Completion criteria

For more info, visit: https://github.com/anthropics/claude-code
EOF
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    
    case "$command" in
        "start")
            build_image
            init_config
            start_session "${2:-}" "${3:-CLAUDE_TASKS.md}"
            ;;
        "list")
            list_sessions
            ;;
        "attach")
            attach_session
            ;;
        "stop")
            stop_sessions
            ;;
        "build")
            docker build -t $DOCKER_IMAGE "$SCRIPT_DIR"
            log "Docker image built successfully"
            ;;
        "config")
            init_config
            echo "Configuration file: $CONFIG_DIR/config.json"
            cat "$CONFIG_DIR/config.json"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
