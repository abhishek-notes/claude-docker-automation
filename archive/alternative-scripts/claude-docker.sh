#!/bin/bash

# Claude Docker Automation System
# Comprehensive wrapper for running Claude Code in Docker

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
  "sessionTimeout": 14400,
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

# Create task file
create_task_file() {
    local task_file="$1"
    
    cat > "$task_file" << 'EOF'
# Claude Autonomous Work Session

## Project Overview
- **Goal**: [Describe the main objective]
- **Scope**: [Define what should be accomplished]
- **Time Estimate**: [Expected duration]

## Tasks

### 1. [Task Name]
- **Description**: [What needs to be done]
- **Requirements**: [Specific requirements]
- **Acceptance Criteria**: [What defines success]

### 2. [Task Name]
- **Description**: [What needs to be done]
- **Requirements**: [Specific requirements]
- **Acceptance Criteria**: [What defines success]

## Technical Requirements
- [ ] Write comprehensive tests
- [ ] Update documentation
- [ ] Follow coding standards
- [ ] Create meaningful commit messages

## Deliverables
- [ ] Working implementation
- [ ] Test coverage > 80%
- [ ] Updated README/docs
- [ ] PROGRESS.md with status updates
- [ ] SUMMARY.md with final results

## Notes
- Work autonomously without asking for permissions
- Create feature branch for changes
- Commit frequently with clear messages
- Document any issues or blockers in ISSUES.md
EOF
    
    info "Created task template: $task_file"
}

# Start Claude session
start_session() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-}"
    local session_duration="${3:-4}"
    
    # Validate project path
    if [ ! -d "$project_path" ]; then
        error "Project path does not exist: $project_path"
        exit 1
    fi
    
    # Get project info
    local project_info=$(get_project_info "$project_path")
    local project_name=$(echo "$project_info" | cut -d: -f1)
    local session_id=$(echo "$project_info" | cut -d: -f2)
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    # Create task file if not provided
    if [ -z "$task_file" ]; then
        task_file="$project_path/CLAUDE_TASKS.md"
        if [ ! -f "$task_file" ]; then
            create_task_file "$task_file"
            
            # Open editor if available
            if command -v code >/dev/null 2>&1; then
                code "$task_file"
            elif command -v nano >/dev/null 2>&1; then
                nano "$task_file"
            fi
            
            echo ""
            read -p "Press Enter after editing the task file to continue..."
        fi
    fi
    
    log "Starting Claude session: $container_name"
    log "Project: $project_path"
    log "Task file: $task_file"
    log "Duration: $session_duration hours"
    echo ""
    
    # Prepare environment variables
    local env_args=()
    
    # Add GitHub token if available
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        env_args+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
    fi
    
    # Add Anthropic API key if available
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        env_args+=(-e "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
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
    
    # Mount Claude config if exists
    if [ -d "$HOME/.claude" ]; then
        mount_args+=(-v "$HOME/.claude:/tmp/.claude:ro")
    fi
    
    # Create session prompt
    local session_prompt="You are starting an autonomous $session_duration hour work session.

Instructions:
1. Read and complete all tasks in CLAUDE_TASKS.md
2. Create a feature branch: claude/session-$session_id
3. Work autonomously using --dangerously-skip-permissions (already enabled)
4. Create PROGRESS.md and update it every 30 minutes
5. Commit changes frequently with meaningful messages
6. Create SUMMARY.md with final results when complete
7. Document any issues in ISSUES.md

You have full permissions in this Docker environment. Begin work now."
    
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
    echo -e "${PURPLE}📊 Session Results:${NC}"
    echo "================================"
    
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
        git log --oneline -5 || true
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

# Web UI (basic version)
start_web_ui() {
    local port="${1:-3456}"
    
    log "Starting web UI on port $port"
    
    # Create a simple web interface container
    docker run -d --rm \
        --name claude-web-ui \
        -p "$port:80" \
        -v "$SCRIPT_DIR/web:/usr/share/nginx/html:ro" \
        nginx:alpine
    
    info "Web UI available at: http://localhost:$port"
    
    # Open browser on macOS
    if command -v open >/dev/null 2>&1; then
        open "http://localhost:$port"
    fi
}

# Show help
show_help() {
    cat << 'EOF'
Claude Docker Automation System

USAGE:
    ./claude-docker.sh [COMMAND] [OPTIONS]

COMMANDS:
    start [path] [task-file] [hours]  Start new Claude session
    list                              List active sessions
    attach                            Attach to existing session
    stop                              Stop all sessions
    web [port]                        Start web UI (default: 3456)
    build                             Build Docker image
    config                            Show configuration
    help                              Show this help

EXAMPLES:
    ./claude-docker.sh start                           # Start in current directory
    ./claude-docker.sh start /path/to/project          # Start in specific project
    ./claude-docker.sh start . tasks.md 8              # 8-hour session with custom tasks
    ./claude-docker.sh list                            # List running sessions
    ./claude-docker.sh attach                          # Attach to session
    ./claude-docker.sh web                             # Start web interface

ENVIRONMENT VARIABLES:
    GITHUB_TOKEN        GitHub personal access token
    ANTHROPIC_API_KEY   Anthropic API key for Claude
    GIT_USER_NAME       Git user name for commits
    GIT_USER_EMAIL      Git user email for commits

CONFIGURATION:
    Config file: ~/.claude-docker/config.json
    Edit this file to customize default behavior.

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
            start_session "${2:-}" "${3:-}" "${4:-4}"
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
        "web")
            start_web_ui "${2:-3456}"
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
