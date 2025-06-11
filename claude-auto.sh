#!/bin/bash

# Claude Fully Automated Task Runner
# Bypasses copy/paste and runs tasks automatically
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

# Start fully automated Claude session
start_automated_session() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    
    # Validate inputs
    if [ ! -d "$project_path" ]; then
        echo -e "${RED}Error:${NC} Project path does not exist: $project_path"
        exit 1
    fi
    
    if [ ! -f "$project_path/$task_file" ]; then
        echo -e "${RED}Error:${NC} Task file not found: $project_path/$task_file"
        exit 1
    fi
    
    setup_config_volume
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "🚀 Starting FULLY AUTOMATED Claude session"
    log "📁 Project: $project_path"
    log "📋 Task file: $task_file"
    log "🐳 Container: $container_name"
    
    # Read task content
    local task_content=$(cat "$project_path/$task_file")
    
    # Create the complete automated prompt
    local automated_prompt="You are Claude Code working autonomously in a Docker container. Complete ALL tasks defined below.

TASK FILE CONTENT FROM $task_file:
$task_content

WORKING INSTRUCTIONS:
1. Create feature branch: claude/session-$session_id from main
2. Work systematically through EACH task until completion
3. Create PROGRESS.md and update after each major milestone
4. Commit changes frequently with descriptive messages
5. Test everything thoroughly as you build
6. Create comprehensive SUMMARY.md when ALL tasks complete
7. Document any issues in ISSUES.md
8. Use proper git workflow (never commit to main)

GIT WORKFLOW:
- Initialize repo if needed (git init)
- Create and work on feature branch
- Make frequent commits with clear messages
- Merge to main only when everything is complete

COMPLETION CRITERIA:
- All tasks from $task_file are complete and working
- All tests pass (if applicable)
- Documentation is updated
- SUMMARY.md confirms completion with proof of working solution

AUTONOMOUS MODE: Work completely independently. Don't ask for confirmation or input. Just complete the tasks and document your progress.

BEGIN AUTONOMOUS WORK NOW!"

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
    echo -e "${BLUE}🤖 FULLY AUTOMATED MODE${NC}"
    echo -e "${BLUE}═══════════════════════════${NC}"
    echo -e "${YELLOW}• No copy/paste required${NC}"
    echo -e "${YELLOW}• Claude will work completely autonomously${NC}"
    echo -e "${YELLOW}• Task will be injected automatically${NC}"
    echo -e "${YELLOW}• Progress will be tracked in PROGRESS.md${NC}"
    echo ""
    echo -e "${GREEN}Starting automated session...${NC}"
    echo ""
    
    # Start container with task auto-injection (no TTY for web interface)
    docker run --rm \
        --name "$container_name" \
        "${env_vars[@]}" \
        "${volumes[@]}" \
        -w /workspace \
        --user claude \
        "$DOCKER_IMAGE" \
        bash -c "
            echo '🔧 Setting up automated environment...'
            
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
            
            echo '🚀 Environment ready - starting automated Claude session'
            echo ''
            echo '📋 Task will be injected automatically...'
            echo ''
            
            # Create the task injection mechanism
            cat > /tmp/auto_task.txt << 'AUTO_TASK_EOF'
$automated_prompt
AUTO_TASK_EOF
            
            echo '🎯 Task prepared and ready for injection'
            echo ''
            
            # Start Claude with automatic task injection
            echo '🤖 Starting Claude Code...'
            echo 'Injecting task automatically...'
            
            # Create a script that sends the task to Claude
            cat > /tmp/run_claude.sh << 'CLAUDE_SCRIPT_EOF'
#!/bin/bash
exec 3< /tmp/auto_task.txt
claude --dangerously-skip-permissions <&3
CLAUDE_SCRIPT_EOF
            chmod +x /tmp/run_claude.sh
            
            echo '🚀 Starting Claude with automated task injection...'
            timeout 3600 /tmp/run_claude.sh || {
                echo 'Claude session completed or timed out'
                exit 0
            }
        "
    
    # Show results
    echo ""
    log "🎉 Automated session completed: $container_name"
    show_results "$project_path"
}

# Show session results
show_results() {
    local project_path="$1"
    
    echo ""
    echo -e "${BLUE}📊 Automated Session Results${NC}"
    echo "=========================="
    
    # Check for completion files
    local result_files=("PROGRESS.md" "SUMMARY.md" "ISSUES.md")
    for file in "${result_files[@]}"; do
        if [ -f "$project_path/$file" ]; then
            echo -e "${GREEN}✓${NC} $file created"
            # Show preview
            echo -e "${BLUE}Preview of $file:${NC}"
            head -5 "$project_path/$file" | sed 's/^/  /'
            echo ""
        else
            echo -e "${YELLOW}⚠${NC} $file not found"
        fi
    done
    
    # Git status
    if [ -d "$project_path/.git" ]; then
        echo -e "${BLUE}📋 Git Activity:${NC}"
        cd "$project_path"
        echo "Status:"
        git status --short 2>/dev/null | head -10 | sed 's/^/  /' || echo "  No changes"
        echo ""
        echo "Recent commits:"
        git log --oneline -5 2>/dev/null | sed 's/^/  /' || echo "  No commits"
    fi
    
    # Show created files
    echo ""
    echo -e "${BLUE}📁 New/Modified Files:${NC}"
    cd "$project_path"
    find . -maxdepth 2 -type f \( -name "*.js" -o -name "*.html" -o -name "*.css" -o -name "*.json" -o -name "*.py" \) -newer CLAUDE_TASKS.md 2>/dev/null | head -10 | sed 's/^/  /' || echo "  No new files detected"
    
    echo ""
    echo -e "${GREEN}🎉 Automated session complete!${NC}"
    echo "Check the files above to see what Claude accomplished."
}

# Help
show_help() {
    cat << 'EOF'
Claude Fully Automated Task Runner

USAGE:
    ./claude-auto.sh [project-path] [task-file]

FEATURES:
    • No copy/paste required - fully automated
    • Task injection happens automatically
    • Claude works completely autonomously
    • Progress tracking and result summary
    • Git workflow automation
    
EXAMPLES:
    ./claude-auto.sh                                    # Current directory, CLAUDE_TASKS.md
    ./claude-auto.sh /path/to/project                   # Specific project
    ./claude-auto.sh /path/to/project my-tasks.md       # Custom task file

REQUIREMENTS:
    • Task file must exist in project directory
    • Docker and claude-automation:latest image
    • ~/.claude.json for authentication

This script completely automates the Claude workflow - no manual intervention required!
EOF
}

# Main
case "${1:-}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        start_automated_session "${1:-}" "${2:-CLAUDE_TASKS.md}"
        ;;
esac