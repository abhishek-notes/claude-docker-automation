#!/bin/bash

# Claude Code with Direct Task Injection
# Simplified approach that works with the current persistent setup

set -euo pipefail

DOCKER_IMAGE="claude-automation:latest"
CONFIG_VOLUME="claude-code-config"
CONTAINER_PREFIX="claude-session"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }

# Check if task file exists
check_task_file() {
    local project_path="$1"
    local task_file="$2"
    local full_path="$project_path/$task_file"
    
    if [ ! -f "$full_path" ]; then
        echo -e "${RED}Error:${NC} Task file not found: $full_path"
        echo ""
        echo "Please create $task_file with your tasks, or run:"
        echo "  ./claude-official-restored.sh start $project_path  # For manual session"
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

# Start Claude with direct task injection
start_direct_task_session() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    
    # Validate project path
    if [ ! -d "$project_path" ]; then
        echo -e "${RED}Error:${NC} Project path does not exist: $project_path"
        exit 1
    fi
    
    # Check task file
    check_task_file "$project_path" "$task_file"
    
    # Setup volume
    setup_config_volume
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "Starting Claude with direct task: $container_name"
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
    
    echo ""
    echo -e "${BLUE}🎯 Starting Claude with direct task injection...${NC}"
    echo -e "${BLUE}📁 Project: $project_path${NC}"
    echo -e "${BLUE}📋 Task: $task_file${NC}"
    echo ""
    echo -e "${YELLOW}📝 COPY THIS TASK WHEN CLAUDE STARTS:${NC}"
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo "$full_prompt"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}👆 Copy the above task and paste it into Claude${NC}"
    echo ""
    echo -e "${GREEN}Starting Claude now...${NC}"
    echo ""
    
    # Start Claude with clean environment
    docker run -it --rm \
        --name "$container_name" \
        "${env_vars[@]}" \
        "${volumes[@]}" \
        -w /workspace \
        --user claude \
        "$DOCKER_IMAGE" \
        bash -c '
            echo "🔧 Setting up environment..."
            
            # Ensure config directory ownership
            sudo chown -R claude:claude /home/claude/.claude 2>/dev/null || true
            
            # Copy host authentication if needed
            if [ -f "/tmp/host-claude.json" ] && [ ! -f "/home/claude/.claude.json" ]; then
                cp /tmp/host-claude.json /home/claude/.claude.json
                chmod 600 /home/claude/.claude.json
            fi
            
            # Git configuration
            if [ -f "/tmp/.gitconfig" ]; then
                cp /tmp/.gitconfig /home/claude/.gitconfig
            fi
            git config --global init.defaultBranch main
            git config --global --add safe.directory /workspace
            
            # GitHub CLI auth
            if [ -n "${GITHUB_TOKEN:-}" ]; then
                echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null || true
            fi
            
            echo "✅ Environment ready!"
            echo ""
            echo "🚀 Starting Claude Code..."
            echo "Remember to paste the task shown above!"
            echo ""
            
            # Start Claude directly
            claude --dangerously-skip-permissions
        '
    
    echo ""
    log "Session completed: $container_name"
    show_session_results "$project_path"
}

# Alternative: Auto-paste approach using script injection
start_autopaste_session() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    
    check_task_file "$project_path" "$task_file"
    setup_config_volume
    
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    # Read task content
    local task_content=$(cat "$project_path/$task_file")
    
    # Environment and volumes
    local env_vars=(
        -e "CLAUDE_CONFIG_DIR=/home/claude/.claude"
        -e "GIT_USER_NAME=${GIT_USER_NAME:-Claude Automation}"
        -e "GIT_USER_EMAIL=${GIT_USER_EMAIL:-claude@automation.local}"
    )
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        env_vars+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
    fi
    
    local volumes=(
        -v "$CONFIG_VOLUME:/home/claude/.claude"
        -v "$project_path:/workspace"
        -v "$HOME/.claude.json:/tmp/host-claude.json:ro"
        -v "$HOME/.gitconfig:/tmp/.gitconfig:ro"
    )
    
    echo ""
    echo -e "${BLUE}🤖 Auto-paste mode: Will attempt to send task automatically${NC}"
    echo ""
    
    # Start with task pre-loaded
    docker run -it --rm \
        --name "$container_name" \
        "${env_vars[@]}" \
        "${volumes[@]}" \
        -w /workspace \
        --user claude \
        "$DOCKER_IMAGE" \
        bash -c "
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
            
            if [ -n \"\${GITHUB_TOKEN:-}\" ]; then
                echo \"\$GITHUB_TOKEN\" | gh auth login --with-token 2>/dev/null || true
            fi
            
            echo '✅ Environment ready!'
            echo ''
            echo '🚀 Starting Claude with task pre-injection...'
            
            # Create a task injection script
            cat > /tmp/task.txt << 'TASK_EOF'
Complete the tasks in $task_file:

$task_content

Create feature branch claude/session-$session_id, work systematically through tasks, create PROGRESS.md, commit frequently, and create SUMMARY.md when complete. Start now!
TASK_EOF
            
            echo ''
            echo '📋 Task ready to send:'
            echo '========================'
            cat /tmp/task.txt
            echo '========================'
            echo ''
            echo 'Starting Claude...'
            
            # Start Claude and send task after a delay
            (
                sleep 3
                echo 'Attempting to send task...'
                cat /tmp/task.txt
            ) &
            
            claude --dangerously-skip-permissions
        "
    
    show_session_results "$project_path"
}

# Show session results
show_session_results() {
    local project_path="$1"
    
    echo ""
    echo -e "${BLUE}📊 Session Results:${NC}"
    echo "=================="
    
    local result_files=("PROGRESS.md" "SUMMARY.md" "ISSUES.md")
    for file in "${result_files[@]}"; do
        if [ -f "$project_path/$file" ]; then
            echo -e "${GREEN}✓${NC} $file created"
        else
            echo -e "${YELLOW}⚠${NC} $file not found"
        fi
    done
    
    if [ -d "$project_path/.git" ]; then
        echo ""
        echo -e "${BLUE}📋 Git Status:${NC}"
        cd "$project_path"
        git status --short 2>/dev/null || true
        
        echo ""
        echo -e "${BLUE}📝 Recent Commits:${NC}"
        git log --oneline -5 2>/dev/null || echo "No commits"
    fi
    
    if [ -f "$project_path/SUMMARY.md" ]; then
        echo ""
        echo -e "${BLUE}📄 Summary Preview:${NC}"
        head -10 "$project_path/SUMMARY.md"
    fi
}

# Help
show_help() {
    cat << 'EOF'
Claude Code with Direct Task Injection

USAGE:
    ./claude-direct-task.sh [mode] [project-path] [task-file]

MODES:
    copy     - Shows task to copy-paste (default, most reliable)
    auto     - Attempts auto-injection (experimental)

EXAMPLES:
    ./claude-direct-task.sh copy /Users/abhishek/Work/coin-flip-app
    ./claude-direct-task.sh auto /Users/abhishek/Work/coin-flip-app

The 'copy' mode shows you exactly what to paste into Claude.
The 'auto' mode attempts to inject the task automatically.

REQUIREMENTS:
    - Task file must exist (CLAUDE_TASKS.md by default)
    - Docker volume claude-code-config will be created/used
    - Project path must be valid directory

This works with the persistent configuration, so no setup prompts
will appear after the first run.
EOF
}

# Main
case "${1:-copy}" in
    "auto")
        start_autopaste_session "${2:-}" "${3:-CLAUDE_TASKS.md}"
        ;;
    "copy")
        start_direct_task_session "${2:-}" "${3:-CLAUDE_TASKS.md}"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        # Treat first argument as project path if not a command
        start_direct_task_session "${1:-}" "${2:-CLAUDE_TASKS.md}"
        ;;
esac