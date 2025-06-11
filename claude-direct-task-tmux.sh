#!/bin/bash

# Claude Code with Direct Task Injection - tmux Enhanced Version
# Opens all tasks in the same tmux session with different windows

set -euo pipefail

DOCKER_IMAGE="claude-automation:latest"
CONFIG_VOLUME="claude-code-config"
CONTAINER_PREFIX="claude-session"
TMUX_SESSION="claude-main"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }

# Setup tmux session
setup_tmux_session() {
    if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log "Creating tmux session: $TMUX_SESSION"
        tmux new-session -d -s "$TMUX_SESSION" -n "dashboard"
        
        # Add a dashboard window
        tmux send-keys -t "$TMUX_SESSION:dashboard" \
            "watch -n 2 'echo \"🤖 Claude Docker Sessions\"; echo \"\"; docker ps --filter name=claude --format \"table {{.Names}}\t{{.Status}}\t{{.Command}}\" | head -20'" Enter
    fi
}

# Check if task file exists
check_task_file() {
    local project_path="$1"
    local task_file="$2"
    local full_path="$project_path/$task_file"
    
    if [ ! -f "$full_path" ]; then
        echo -e "${RED}Error:${NC} Task file not found: $full_path"
        echo ""
        echo "Please create $task_file with your tasks, or run:"
        echo "  ./claude-official.sh start $project_path  # For manual session"
        exit 1
    fi
    
    log "✅ Found task file: $task_file"
}

# Setup config volume
setup_config_volume() {
    if ! docker volume inspect "$CONFIG_VOLUME" >/dev/null 2>&1; then
        log "Creating persistent config volume: $CONFIG_VOLUME"
        docker volume create "$CONFIG_VOLUME"
    else
        log "Using existing config volume: $CONFIG_VOLUME"
    fi
}

# Start Claude with direct task injection in tmux
start_direct_task_session() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    local task_name="${3:-$(basename "$project_path")}"
    
    # Validate project path
    if [ ! -d "$project_path" ]; then
        echo -e "${RED}Error:${NC} Project path does not exist: $project_path"
        exit 1
    fi
    
    # Check task file
    check_task_file "$project_path" "$task_file"
    
    # Setup
    setup_config_volume
    setup_tmux_session
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${task_name}-${session_id}"
    local window_name="${task_name}-${session_id:9:6}"  # Use time portion for uniqueness
    
    log "Starting Claude in tmux window: $window_name"
    log "Project: $project_path"
    log "Task file: $task_file"
    
    # Read task content
    local task_content=$(cat "$project_path/$task_file")
    
    # Create comprehensive task prompt
    local full_prompt="You are Claude Code working in a Docker container. I need you to complete the tasks defined in $task_file.

TASK CONTENT FROM $task_file:
$task_content

WORKING INSTRUCTIONS:
1. Create a feature branch: claude/session-$session_id from main branch
2. Work systematically through EACH task listed above until completion
3. Create PROGRESS.md and update it after completing each major task
4. Commit changes frequently with meaningful messages
5. Test everything thoroughly as you build
6. Create comprehensive SUMMARY.md when ALL tasks are complete
7. Document any issues in ISSUES.md
8. Use proper git workflow (never commit directly to main)

GIT SETUP:
- Use 'main' as default branch
- Create feature branches for all work
- Make descriptive commit messages

COMPLETION CRITERIA:
- All tasks from $task_file are complete
- All tests pass (if applicable)
- Documentation is updated
- SUMMARY.md confirms completion

You have full permissions in this container. Work autonomously until all tasks are genuinely complete!

Please start by analyzing the project structure and then begin working on the first task."
    
    # Environment variables
    local env_vars=(
        -e "CLAUDE_CONFIG_DIR=/home/claude/.claude"
        -e "NODE_OPTIONS=--max-old-space-size=4096"
        -e "GIT_USER_NAME=${GIT_USER_NAME:-Claude Automation}"
        -e "GIT_USER_EMAIL=${GIT_USER_EMAIL:-claude@automation.local}"
    )
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        env_vars+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
    fi
    
    # Volume mounts
    local volumes=(
        -v "$CONFIG_VOLUME:/home/claude/.claude"
        -v "$project_path:/workspace"
        -v "$HOME/.claude.json:/tmp/host-claude.json:ro"
        -v "$HOME/.gitconfig:/tmp/.gitconfig:ro"
    )
    
    # Create the task prompt file
    echo "$full_prompt" > "/tmp/claude_task_${session_id}.txt"
    
    # Create tmux window with the Docker command
    tmux new-window -t "$TMUX_SESSION" -n "$window_name" -c "$project_path"
    
    # Send the Docker run command to the new window
    tmux send-keys -t "$TMUX_SESSION:$window_name" "
echo -e '${BLUE}🎯 Starting Claude with direct task injection...${NC}'
echo -e '${BLUE}📁 Project: $project_path${NC}'
echo -e '${BLUE}📋 Task: $task_file${NC}'
echo ''
echo -e '${YELLOW}📝 COPY THIS TASK WHEN CLAUDE STARTS:${NC}'
echo ''
echo -e '${BLUE}════════════════════════════════════════${NC}'
cat /tmp/claude_task_${session_id}.txt
echo -e '${BLUE}════════════════════════════════════════${NC}'
echo ''
echo -e '${YELLOW}👆 Copy the above task and paste it into Claude${NC}'
echo ''
echo -e '${GREEN}Starting Claude now...${NC}'
echo ''

docker run -it --rm \\
    --name '$container_name' \\
    ${env_vars[@]} \\
    ${volumes[@]} \\
    -w /workspace \\
    --user claude \\
    '$DOCKER_IMAGE' \\
    bash -c '
        echo \"🔧 Setting up environment...\"
        
        # Ensure config directory ownership
        sudo chown -R claude:claude /home/claude/.claude 2>/dev/null || true
        
        # Copy host authentication if needed
        if [ -f \"/tmp/host-claude.json\" ] && [ ! -f \"/home/claude/.claude.json\" ]; then
            cp /tmp/host-claude.json /home/claude/.claude.json
            chmod 600 /home/claude/.claude.json
        fi
        
        # Git configuration
        if [ -f \"/tmp/.gitconfig\" ]; then
            cp /tmp/.gitconfig /home/claude/.gitconfig
        fi
        git config --global init.defaultBranch main
        git config --global --add safe.directory /workspace
        
        # GitHub CLI auth
        if [ -n \"\${GITHUB_TOKEN:-}\" ]; then
            echo \"\$GITHUB_TOKEN\" | gh auth login --with-token 2>/dev/null || true
        fi
        
        echo \"✅ Environment ready!\"
        echo \"\"
        echo \"🚀 Starting Claude Code...\"
        echo \"Remember to paste the task shown above!\"
        echo \"\"
        
        # Start Claude directly
        claude --dangerously-skip-permissions
    '

echo ''
echo '✅ Session completed!'
rm -f /tmp/claude_task_${session_id}.txt
" Enter
    
    # Switch to the new window if we're in tmux
    if [ -n "${TMUX:-}" ]; then
        tmux select-window -t "$TMUX_SESSION:$window_name"
    else
        # If not in tmux, attach to the session
        echo ""
        log "Attaching to tmux session..."
        tmux attach-session -t "$TMUX_SESSION"
    fi
}

# Update task API integration
launch_from_api() {
    local task_name="$1"
    local project_path="$2"
    local task_file="${3:-CLAUDE_TASKS.md}"
    
    # Use the tmux-enhanced version
    start_direct_task_session "$project_path" "$task_file" "$task_name"
}

# List all Claude sessions
list_sessions() {
    echo -e "${BLUE}=== Active Claude tmux Windows ===${NC}"
    tmux list-windows -t "$TMUX_SESSION" 2>/dev/null | grep -v "dashboard" | \
        awk '{print "  " $1 " " $2}' | sed 's/:/ -/'
    
    echo -e "\n${BLUE}=== Running Claude Docker Containers ===${NC}"
    docker ps --filter "name=claude" --format "table {{.Names}}\t{{.Status}}" | head -10
}

# Attach to tmux session
attach_session() {
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        tmux attach-session -t "$TMUX_SESSION"
    else
        echo -e "${RED}No active Claude tmux session found.${NC}"
        echo -e "${YELLOW}Start a new task to create the session.${NC}"
    fi
}

# Help
show_help() {
    cat << 'EOF'
Claude Code with Direct Task Injection - tmux Enhanced

USAGE:
    ./claude-direct-task.sh [command] [args...]

COMMANDS:
    start <path> [task-file] [name]  - Start new Claude task in tmux window
    api <name> <path> [task-file]    - Launch from API (for task-api.js)
    list                             - List all active sessions
    attach                           - Attach to tmux session
    help                             - Show this help

EXAMPLES:
    ./claude-direct-task.sh start /Users/abhishek/Work/coin-flip-app
    ./claude-direct-task.sh start ~/Work/project TASKS.md "web-scraper"
    ./claude-direct-task.sh list
    ./claude-direct-task.sh attach

TMUX SHORTCUTS (when attached):
    Ctrl-b w     - List and switch between windows
    Ctrl-b d     - Detach (leave everything running)
    Ctrl-b [     - Enter scroll mode (q to exit)
    Ctrl-b &     - Kill current window

All tasks open in the same tmux session as different windows.
EOF
}

# Main
case "${1:-start}" in
    "start")
        start_direct_task_session "${2:-}" "${3:-CLAUDE_TASKS.md}" "${4:-}"
        ;;
    "api")
        # Called from task-api.js: api <name> <path> [task-file]
        launch_from_api "${2:-task}" "${3:-$(pwd)}" "${4:-CLAUDE_TASKS.md}"
        ;;
    "list"|"ls")
        list_sessions
        ;;
    "attach"|"a")
        attach_session
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        # Default to start with first arg as path
        start_direct_task_session "${1:-}" "${2:-CLAUDE_TASKS.md}" "${3:-}"
        ;;
esac