#!/bin/bash

# Claude Max Autonomous Launcher - No Setup Prompts
# Completely automated task execution

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
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check Claude Max authentication
check_claude_auth() {
    info "Checking Claude Max authentication..."
    
    if [ ! -f "$HOME/.claude.json" ]; then
        error "Claude authentication not found at ~/.claude.json"
        echo ""
        echo "Please make sure you're logged into Claude Code on your Mac:"
        echo "1. Run 'claude' in your Mac terminal"
        echo "2. Complete the authentication process"
        echo "3. Try this script again"
        exit 1
    fi
    
    log "✅ Claude Max authentication ready"
}

# Start fully autonomous session
start_autonomous_session() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    
    # Validate inputs
    if [ ! -d "$project_path" ]; then
        error "Project path does not exist: $project_path"
        exit 1
    fi
    
    if [ ! -f "$project_path/$task_file" ]; then
        error "Task file not found: $project_path/$task_file"
        echo "Expected: $project_path/$task_file"
        exit 1
    fi
    
    # Check authentication
    check_claude_auth
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "Starting autonomous Claude Max session: $container_name"
    log "Project: $project_path"
    log "Task file: $task_file"
    echo ""
    
    # Build environment variables
    local env_args=()
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        env_args+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
        info "GitHub integration enabled"
    fi
    
    env_args+=(-e "GIT_USER_NAME=${GIT_USER_NAME:-Claude Automation}")
    env_args+=(-e "GIT_USER_EMAIL=${GIT_USER_EMAIL:-claude@automation.local}")
    
    # Build mount arguments
    local mount_args=()
    
    # Mount authentication (read-only source, writable copy created inside)
    mount_args+=(-v "$HOME/.claude.json:/home/claude/.claude.json.readonly:ro")
    
    # Mount configs
    if [ -d "$HOME/.claude" ]; then
        mount_args+=(-v "$HOME/.claude:/home/claude/.claude-host:ro")
    fi
    
    local claude_desktop_dir="$HOME/Library/Application Support/Claude"
    if [ -d "$claude_desktop_dir" ]; then
        mount_args+=(-v "$claude_desktop_dir:/home/claude/.claude-desktop:ro")
    fi
    
    if [ -f "$HOME/.gitconfig" ]; then
        mount_args+=(-v "$HOME/.gitconfig:/tmp/.gitconfig:ro")
    fi
    
    # Create the autonomous task prompt
    local session_prompt="You are starting a fully autonomous work session using Claude Max authentication.

AUTHENTICATION: ✅ Ready (setup prompts disabled)

TASK INSTRUCTIONS:
1. Read and complete ALL tasks in $task_file
2. Create a feature branch: claude/session-$session_id from main branch  
3. Work systematically through each task until completion
4. Create PROGRESS.md and update it after completing each major task
5. Commit changes frequently with meaningful messages
6. Test everything thoroughly as you build
7. Create comprehensive SUMMARY.md when ALL tasks are complete
8. Document any issues in ISSUES.md
9. Exit ONLY when all tasks are genuinely complete and working

GIT SETUP:
- Use 'main' as the default branch (not master)
- Create all new branches from main
- Never commit directly to main

WORKING MODE:
- You have full permissions in this Docker environment
- Work until the job is done - no time limits
- Focus on completing all requirements thoroughly
- No setup prompts or interruptions

BEGIN AUTONOMOUS WORK NOW!"
    
    info "Starting fully autonomous session..."
    echo ""
    echo -e "${YELLOW}🤖 Claude will work autonomously until all tasks are complete${NC}"
    echo -e "${YELLOW}📊 Monitor progress: tail -f $project_path/PROGRESS.md${NC}"
    echo ""
    
    # Start the autonomous container
    docker run -it --rm \
        --name "$container_name" \
        "${env_args[@]}" \
        "${mount_args[@]}" \
        -v "$project_path:/workspace" \
        -w /workspace \
        $DOCKER_IMAGE \
        bash -c "
            # Wait a moment for setup
            sleep 2
            
            echo '🚀 Starting autonomous Claude Max session...'
            
            # Start Claude directly with the task - no interactive prompts
            claude --dangerously-skip-permissions -p \"$session_prompt\"
        "
    
    # Post-session results
    echo ""
    log "Autonomous session completed: $container_name"
    
    # Show comprehensive results
    echo ""
    echo -e "${BLUE}📊 Task Completion Results:${NC}"
    echo "==============================="
    
    local result_files=("PROGRESS.md" "SUMMARY.md" "ISSUES.md")
    for file in "${result_files[@]}"; do
        if [ -f "$project_path/$file" ]; then
            echo -e "${GREEN}✓${NC} $file created"
        else
            echo -e "${YELLOW}⚠${NC} $file not found"
        fi
    done
    
    # Git analysis
    if [ -d "$project_path/.git" ]; then
        echo ""
        echo -e "${BLUE}📋 Git Analysis:${NC}"
        cd "$project_path"
        
        current_branch=$(git branch --show-current 2>/dev/null || echo "none")
        echo "Current branch: $current_branch"
        
        # Count commits
        commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
        echo "Total commits: $commit_count"
        
        # Show files changed
        if [ "$commit_count" -gt 0 ]; then
            changed_files=$(git diff --name-only HEAD~1 2>/dev/null | wc -l || echo "0")
            echo "Files modified: $changed_files"
        fi
        
        # Show recent commits
        echo ""
        echo -e "${BLUE}📝 Recent Commits:${NC}"
        git log --oneline -5 2>/dev/null || echo "No commits yet"
        
        # Show Claude branches
        echo ""
        echo -e "${BLUE}🌿 Claude Branches:${NC}"
        git branch -a | grep claude || echo "No Claude branches found"
    fi
    
    # Project structure analysis
    echo ""
    echo -e "${BLUE}📁 Project Structure:${NC}"
    cd "$project_path"
    find . -maxdepth 2 -type f -name "*.js" -o -name "*.html" -o -name "*.css" -o -name "*.json" -o -name "*.md" | head -20
    
    # Show summary preview
    if [ -f "$project_path/SUMMARY.md" ]; then
        echo ""
        echo -e "${BLUE}📄 Session Summary:${NC}"
        echo "==================="
        head -20 "$project_path/SUMMARY.md"
        echo ""
        echo "Full summary: $project_path/SUMMARY.md"
    fi
    
    # Final status
    echo ""
    if [ -f "$project_path/SUMMARY.md" ] && [ -f "$project_path/PROGRESS.md" ]; then
        echo -e "${GREEN}🎉 Autonomous session completed successfully!${NC}"
        echo -e "${GREEN}📋 Check SUMMARY.md for full results${NC}"
    else
        echo -e "${YELLOW}⚠️  Session may have ended prematurely${NC}"
        echo -e "${YELLOW}📋 Check logs and project files${NC}"
    fi
}

# Show help
show_help() {
    cat << 'EOF'
Claude Max Autonomous Launcher - Zero Interaction Required

This script runs Claude completely autonomously using your Claude Max 
subscription. No setup prompts, no manual interaction required.

USAGE:
    ./claude-autonomous.sh [project-path] [task-file]

FEATURES:
    ✅ No setup prompts or theme selection
    ✅ No authentication prompts  
    ✅ Fully autonomous operation
    ✅ Uses your Claude Max subscription
    ✅ Automatic git branch management
    ✅ Comprehensive result reporting

EXAMPLES:
    ./claude-autonomous.sh                                # Current directory
    ./claude-autonomous.sh /path/to/project               # Specific project  
    ./claude-autonomous.sh /path/to/project tasks.md      # Custom task file

MONITORING:
    While Claude works autonomously, you can monitor:
    - tail -f /path/to/project/PROGRESS.md
    - docker logs claude-session-[project]-[timestamp]

The session will run until ALL tasks are complete, then exit automatically.
EOF
}

# Main function
case "${1:-start}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        start_autonomous_session "${1:-}" "${2:-CLAUDE_TASKS.md}"
        ;;
esac
