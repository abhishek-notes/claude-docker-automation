#!/bin/bash

# Claude Web Direct Task Runner
# Uses the working claude-direct-task.sh approach but for web interface
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

# Setup config volume
setup_config_volume() {
    if ! docker volume inspect "$CONFIG_VOLUME" >/dev/null 2>&1; then
        log "Creating persistent config volume: $CONFIG_VOLUME"
        docker volume create "$CONFIG_VOLUME"
    fi
}

# Start web-direct Claude session
start_web_direct_session() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    
    # Validate inputs
    if [ ! -d "$project_path" ]; then
        echo "Error: Project path does not exist: $project_path"
        exit 1
    fi
    
    if [ ! -f "$project_path/$task_file" ]; then
        echo "Error: Task file not found: $project_path/$task_file"
        exit 1
    fi
    
    setup_config_volume
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "🚀 Starting Web Direct Claude Session"
    log "📁 Project: $project_path"
    log "📋 Task file: $task_file"
    log "🐳 Container: $container_name"
    
    # Read task content
    local task_content=$(cat "$project_path/$task_file")
    
    # Create comprehensive task prompt (based on claude-direct-task.sh)
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
    echo "🎯 WEB DIRECT MODE - Based on working claude-direct-task.sh"
    echo "=========================================================="
    echo "Project: $project_path"
    echo "Task: $task_file"
    echo ""
    echo "COPY THIS TASK TO CLAUDE WHEN IT STARTS:"
    echo ""
    echo "════════════════════════════════════════"
    echo "$full_prompt"
    echo "════════════════════════════════════════"
    echo ""
    echo "Starting Claude now..."
    echo ""
    
    # Start Claude with clean environment (using the working approach from claude-direct-task.sh)
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
            
            # Start Claude directly (this is the working approach)
            claude --dangerously-skip-permissions
        '
    
    echo ""
    log "Session completed: $container_name"
    show_session_results "$project_path"
}

# Show session results
show_session_results() {
    local project_path="$1"
    
    echo ""
    echo "📊 Session Results:"
    echo "=================="
    
    local result_files=("PROGRESS.md" "SUMMARY.md" "ISSUES.md")
    for file in "${result_files[@]}"; do
        if [ -f "$project_path/$file" ]; then
            echo "✓ $file created"
        else
            echo "⚠ $file not found"
        fi
    done
    
    if [ -d "$project_path/.git" ]; then
        echo ""
        echo "📋 Git Status:"
        cd "$project_path"
        git status --short 2>/dev/null || true
        
        echo ""
        echo "📝 Recent Commits:"
        git log --oneline -5 2>/dev/null || echo "No commits"
    fi
    
    if [ -f "$project_path/SUMMARY.md" ]; then
        echo ""
        echo "📄 Summary Preview:"
        head -10 "$project_path/SUMMARY.md"
    fi
}

# Main
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "Claude Web Direct Task Runner"
        echo "Usage: $0 [project-path] [task-file]"
        echo ""
        echo "This uses the proven claude-direct-task.sh approach"
        echo "You'll need to copy/paste the task into Claude when it starts"
        ;;
    *)
        start_web_direct_session "${1:-}" "${2:-CLAUDE_TASKS.md}"
        ;;
esac