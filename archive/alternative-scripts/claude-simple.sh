#!/bin/bash

# Simple Claude Launcher - Easy Copy-Paste Approach
# Provides ready-to-paste task instructions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="claude-automation:latest"
CONTAINER_PREFIX="claude-session"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }

# Main function
start_simple_session() {
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
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "Starting simple Claude session: $container_name"
    log "Project: $project_path"
    echo ""
    
    # Build environment and mounts
    local env_args=()
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        env_args+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
    fi
    env_args+=(-e "GIT_USER_NAME=${GIT_USER_NAME:-Claude Automation}")
    env_args+=(-e "GIT_USER_EMAIL=${GIT_USER_EMAIL:-claude@automation.local}")
    
    local mount_args=()
    mount_args+=(-v "$HOME/.claude.json:/home/claude/.claude.json.readonly:ro")
    if [ -d "$HOME/.claude" ]; then
        mount_args+=(-v "$HOME/.claude:/home/claude/.claude-host:ro")
    fi
    if [ -f "$HOME/.gitconfig" ]; then
        mount_args+=(-v "$HOME/.gitconfig:/tmp/.gitconfig:ro")
    fi
    
    # Create the task prompt from the task file
    local task_content=$(cat "$project_path/$task_file")
    
    # Enhanced prompt that includes the task content
    local full_prompt="You are starting a task-completion based autonomous work session.

TASK FILE CONTENT:
$task_content

WORK INSTRUCTIONS:
1. Create a feature branch: claude/session-$session_id from main branch
2. Work systematically through EACH task listed above until completion
3. Create PROGRESS.md and update it after completing each major task
4. Commit changes frequently with meaningful messages
5. Test everything thoroughly as you build
6. Create comprehensive SUMMARY.md when ALL tasks are complete
7. Document any issues in ISSUES.md
8. Exit ONLY when all tasks are genuinely complete and working

GIT SETUP:
- Use 'main' as default branch
- Create feature branches for all work
- Never commit directly to main

COMPLETION CRITERIA:
- All tasks from the task file are complete
- All tests pass
- Documentation is complete
- SUMMARY.md confirms completion

You have full permissions. Work until the job is completely done!

BEGIN AUTONOMOUS WORK NOW!"
    
    echo -e "${BLUE}📋 STEP-BY-STEP INSTRUCTIONS:${NC}"
    echo "=============================="
    echo ""
    echo -e "${YELLOW}1.${NC} I'm starting Claude in a Docker container"
    echo -e "${YELLOW}2.${NC} When you see the bypass permissions prompt:"
    echo -e "   ${GREEN}Press '2' then Enter${NC} to accept"
    echo ""
    echo -e "${YELLOW}3.${NC} Once Claude starts, copy and paste this EXACT task:"
    echo ""
    echo -e "${BLUE}═══ COPY FROM HERE ═══${NC}"
    echo "$full_prompt"
    echo -e "${BLUE}═══ COPY TO HERE ═══${NC}"
    echo ""
    echo -e "${YELLOW}4.${NC} Claude will then work autonomously until all tasks are complete!"
    echo ""
    echo -e "${GREEN}Starting container now...${NC}"
    echo ""
    
    # Start the container
    docker run -it --rm \
        --name "$container_name" \
        "${env_args[@]}" \
        "${mount_args[@]}" \
        -v "$project_path:/workspace" \
        -w /workspace \
        $DOCKER_IMAGE \
        claude --dangerously-skip-permissions
    
    # Post-session results
    echo ""
    log "Session completed: $container_name"
    
    # Show results
    echo ""
    echo -e "${BLUE}📊 Session Results:${NC}"
    echo "==================="
    
    local result_files=("PROGRESS.md" "SUMMARY.md" "ISSUES.md")
    for file in "${result_files[@]}"; do
        if [ -f "$project_path/$file" ]; then
            echo -e "${GREEN}✓${NC} $file created"
        else
            echo -e "${YELLOW}⚠${NC} $file not found"
        fi
    done
    
    # Show file structure
    echo ""
    echo -e "${BLUE}📁 Project Files:${NC}"
    cd "$project_path"
    find . -maxdepth 2 -type f -name "*.js" -o -name "*.html" -o -name "*.css" -o -name "*.json" -o -name "*.md" | sort
    
    # Git status
    if [ -d "$project_path/.git" ]; then
        echo ""
        echo -e "${BLUE}📋 Git Status:${NC}"
        git status --short
        echo ""
        echo -e "${BLUE}📝 Commits:${NC}"
        git log --oneline -5 2>/dev/null || echo "No commits"
    fi
    
    # Show summary
    if [ -f "$project_path/SUMMARY.md" ]; then
        echo ""
        echo -e "${BLUE}📄 Summary Preview:${NC}"
        head -15 "$project_path/SUMMARY.md"
        echo ""
        echo "Full summary: $project_path/SUMMARY.md"
    fi
}

# Show help
show_help() {
    cat << 'EOF'
Simple Claude Launcher - Copy-Paste Approach

This script makes it easy to start autonomous Claude sessions by providing
the exact task instructions to copy and paste.

USAGE:
    ./claude-simple.sh [project-path] [task-file]

PROCESS:
    1. Script starts Claude in Docker container
    2. Shows you exactly what to copy-paste
    3. You accept bypass permissions (press 2 + Enter)
    4. You paste the provided task instructions
    5. Claude works autonomously until complete

EXAMPLES:
    ./claude-simple.sh /Users/abhishek/Work/coin-flip-app
    ./claude-simple.sh . my-tasks.md

The script reads your task file and creates a comprehensive prompt
that includes all your requirements for autonomous execution.
EOF
}

# Main
case "${1:-start}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        start_simple_session "${1:-}" "${2:-CLAUDE_TASKS.md}"
        ;;
esac
