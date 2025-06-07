#!/bin/bash

# Claude Web Automation - Non-interactive version for web interface
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

# Start web-compatible Claude session
start_web_session() {
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
    
    log "🚀 Starting Web-Compatible Claude Session"
    log "📁 Project: $project_path"
    log "📋 Task file: $task_file"
    log "🐳 Container: $container_name"
    
    # Read task content for logging
    local task_content=$(cat "$project_path/$task_file")
    
    # Environment setup
    local env_vars=(
        -e "CLAUDE_CONFIG_DIR=/home/claude/.claude"
        -e "NODE_OPTIONS=--max-old-space-size=4096"
        -e "GIT_USER_NAME=${GIT_USER_NAME:-Claude Automation}"
        -e "GIT_USER_EMAIL=${GIT_USER_EMAIL:-claude@automation.local}"
        -e "AUTOMATED_MODE=true"
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
    echo "🤖 WEB AUTOMATION MODE"
    echo "======================"
    echo "• Non-interactive Docker execution"
    echo "• Task file will be processed by Claude"
    echo "• Progress tracked in real-time"
    echo "• Results saved to project directory"
    echo ""
    echo "Starting session..."
    echo ""
    
    # Start container (non-interactive for web)
    docker run --rm \
        --name "$container_name" \
        "${env_vars[@]}" \
        "${volumes[@]}" \
        -w /workspace \
        --user claude \
        "$DOCKER_IMAGE" \
        bash -c "
            echo '🔧 Setting up web automation environment...'
            
            # Setup environment
            sudo chown -R claude:claude /home/claude/.claude 2>/dev/null || true
            
            # Copy authentication
            if [ -f '/tmp/host-claude.json' ] && [ ! -f '/home/claude/.claude.json' ]; then
                cp /tmp/host-claude.json /home/claude/.claude.json
                chmod 600 /home/claude/.claude.json
                echo '✅ Claude authentication configured'
            fi
            
            # Git setup
            if [ -f '/tmp/.gitconfig' ]; then
                cp /tmp/.gitconfig /home/claude/.gitconfig
                echo '✅ Git configuration applied'
            fi
            git config --global init.defaultBranch main
            git config --global --add safe.directory /workspace
            
            # GitHub CLI setup
            if [ -n \"\${GITHUB_TOKEN:-}\" ]; then
                echo \"\$GITHUB_TOKEN\" | gh auth login --with-token 2>/dev/null || true
                echo '✅ GitHub CLI authenticated'
            fi
            
            echo '📋 Task file found: $task_file'
            echo '🎯 Processing task automatically...'
            echo ''
            
            # Initialize git repo if needed
            if [ ! -d '.git' ]; then
                echo '📦 Initializing git repository...'
                git init
                git add .
                git commit -m 'Initial commit before Claude automation'
            fi
            
            # Create initial progress file
            echo '# Claude Automation Progress' > PROGRESS.md
            echo '' >> PROGRESS.md
            echo '## Session Started' >> PROGRESS.md
            echo \"Date: \$(date)\" >> PROGRESS.md
            echo \"Container: $container_name\" >> PROGRESS.md
            echo \"Task file: $task_file\" >> PROGRESS.md
            echo '' >> PROGRESS.md
            echo '## Task Overview' >> PROGRESS.md
            echo \"Reading tasks from $task_file...\" >> PROGRESS.md
            echo '' >> PROGRESS.md
            
            # Create feature branch
            branch_name=\"claude/session-$session_id\"
            echo \"📝 Creating feature branch: \$branch_name\"
            git checkout -b \"\$branch_name\" 2>/dev/null || true
            
            echo '🚀 Starting Claude Code in autonomous mode...'
            echo 'Task will be read from $task_file'
            echo ''
            
            # Start Claude with the task file path
            # Claude will be prompted to read the task file
            echo 'You are Claude Code working autonomously. Please read the file $task_file and complete all tasks listed there. Work systematically through each task, create progress updates in PROGRESS.md, commit changes frequently with clear messages, and create a comprehensive SUMMARY.md when complete. Create feature branch claude/session-$session_id for your work. Begin by reading $task_file now.' | claude --dangerously-skip-permissions || {
                echo '⚠️ Claude session ended'
                
                # Create basic summary if none exists
                if [ ! -f 'SUMMARY.md' ]; then
                    echo '# Claude Automation Summary' > SUMMARY.md
                    echo '' >> SUMMARY.md
                    echo '## Session Information' >> SUMMARY.md
                    echo \"- Container: $container_name\" >> SUMMARY.md
                    echo \"- Date: \$(date)\" >> SUMMARY.md
                    echo \"- Task file: $task_file\" >> SUMMARY.md
                    echo '' >> SUMMARY.md
                    echo '## Status' >> SUMMARY.md
                    echo 'Session completed. Check PROGRESS.md for details.' >> SUMMARY.md
                fi
                
                # Final commit
                git add . 2>/dev/null || true
                git commit -m 'Claude automation session completed' 2>/dev/null || true
                
                echo '✅ Session cleanup completed'
            }
            
            echo ''
            echo '🎉 Claude web automation session completed!'
        "
    
    # Show results
    echo ""
    log "🎉 Web session completed: $container_name"
    show_results "$project_path"
}

# Show session results
show_results() {
    local project_path="$1"
    
    echo ""
    echo "📊 Web Session Results"
    echo "======================"
    
    # Check for completion files
    local result_files=("PROGRESS.md" "SUMMARY.md" "ISSUES.md")
    for file in "${result_files[@]}"; do
        if [ -f "$project_path/$file" ]; then
            echo "✓ $file created"
            # Show preview for logs
            echo "Preview of $file:"
            head -5 "$project_path/$file" | sed 's/^/  /'
            echo ""
        else
            echo "⚠ $file not found"
        fi
    done
    
    # Git status
    if [ -d "$project_path/.git" ]; then
        echo "📋 Git Activity:"
        cd "$project_path"
        echo "Status:"
        git status --short 2>/dev/null | head -10 | sed 's/^/  /' || echo "  No changes"
        echo ""
        echo "Recent commits:"
        git log --oneline -5 2>/dev/null | sed 's/^/  /' || echo "  No commits"
    fi
    
    echo ""
    echo "🎉 Web session complete!"
}

# Main
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "Claude Web Automation - Non-interactive version for web interface"
        echo "Usage: $0 [project-path] [task-file]"
        ;;
    *)
        start_web_session "${1:-}" "${2:-CLAUDE_TASKS.md}"
        ;;
esac