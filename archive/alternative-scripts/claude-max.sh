#!/bin/bash

# Claude Max Authentication Docker Launcher - FIXED
# Creates writable copies of authentication files

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
    
    # Check if main Claude auth file exists
    if [ ! -f "$HOME/.claude.json" ]; then
        error "Claude authentication not found at ~/.claude.json"
        echo ""
        echo "Please make sure you're logged into Claude Code on your Mac:"
        echo "1. Run 'claude' in your Mac terminal"
        echo "2. Complete the authentication process"
        echo "3. Try this script again"
        exit 1
    fi
    
    # Check Claude Desktop config
    local claude_desktop_dir="$HOME/Library/Application Support/Claude"
    if [ ! -d "$claude_desktop_dir" ]; then
        warning "Claude Desktop config not found - this is optional"
    else
        info "Found Claude Desktop configuration"
    fi
    
    # Check Claude Code config
    if [ -d "$HOME/.claude" ]; then
        info "Found Claude Code configuration"
    fi
    
    log "✅ Claude Max authentication ready"
}

# Start session with proper authentication mounting
start_session_with_auth() {
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
    
    # Check authentication first
    check_claude_auth
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "Starting Claude Max session: $container_name"
    log "Project: $project_path"
    log "Task file: $task_file"
    echo ""
    
    # Build environment variables
    local env_args=()
    
    # Add GitHub token if available
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        env_args+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
        info "GitHub integration enabled"
    fi
    
    # Add git configuration
    env_args+=(-e "GIT_USER_NAME=${GIT_USER_NAME:-Claude Automation}")
    env_args+=(-e "GIT_USER_EMAIL=${GIT_USER_EMAIL:-claude@automation.local}")
    
    # Build mount arguments for authentication
    local mount_args=()
    
    # Mount Claude Max authentication as READONLY, then copy to writable location
    mount_args+=(-v "$HOME/.claude.json:/home/claude/.claude.json.readonly:ro")
    info "Mounted Claude Max authentication (will create writable copy)"
    
    # Mount Claude Code config directory
    if [ -d "$HOME/.claude" ]; then
        mount_args+=(-v "$HOME/.claude:/home/claude/.claude-host:ro")
        info "Mounted Claude Code configuration"
    fi
    
    # Mount Claude Desktop config if available
    local claude_desktop_dir="$HOME/Library/Application Support/Claude"
    if [ -d "$claude_desktop_dir" ]; then
        mount_args+=(-v "$claude_desktop_dir:/home/claude/.claude-desktop:ro")
        info "Mounted Claude Desktop configuration"
    fi
    
    # Mount git config
    if [ -f "$HOME/.gitconfig" ]; then
        mount_args+=(-v "$HOME/.gitconfig:/tmp/.gitconfig:ro")
    fi
    
    # Enhanced session prompt
    local session_prompt="You are starting a task-completion based autonomous work session using Claude Max authentication.

AUTHENTICATION SETUP:
✅ Your Claude Max credentials are mounted and configured
✅ You should be able to start working immediately

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

Begin work now - your authentication is ready!"
    
    info "Starting container with Claude Max authentication..."
    echo ""
    
    # Start the container with proper authentication
    docker run -it --rm \
        --name "$container_name" \
        "${env_args[@]}" \
        "${mount_args[@]}" \
        -v "$project_path:/workspace" \
        -w /workspace \
        $DOCKER_IMAGE \
        bash -c "
            echo '🔐 Setting up Claude Max authentication...'
            
            # The entrypoint script will handle creating writable copies
            echo '🚀 Starting Claude with your Max subscription...'
            echo ''
            
            # Start Claude with the task prompt
            claude --dangerously-skip-permissions -p \"$session_prompt\"
        "
    
    # Post-session results
    echo ""
    log "Session completed: $container_name"
    
    # Show results
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
    
    # Show git status
    if [ -d "$project_path/.git" ]; then
        echo ""
        echo -e "${BLUE}📋 Git Status:${NC}"
        cd "$project_path"
        
        # Check current branch
        current_branch=$(git branch --show-current 2>/dev/null || echo "none")
        echo "Current branch: $current_branch"
        
        # Show status
        git status --short
        
        # Show recent commits
        echo ""
        echo -e "${BLUE}📝 Recent Commits:${NC}"
        git log --oneline -5 2>/dev/null || echo "No commits yet"
        
        # Show Claude branches
        echo ""
        echo -e "${BLUE}🌿 Claude Branches:${NC}"
        git branch -a | grep claude || echo "No Claude branches found"
    fi
    
    # Show summary if available
    if [ -f "$project_path/SUMMARY.md" ]; then
        echo ""
        echo -e "${BLUE}📄 Task Summary Preview:${NC}"
        echo "=========================="
        head -15 "$project_path/SUMMARY.md"
        echo ""
        echo "Full summary: $project_path/SUMMARY.md"
    fi
}

# Show help
show_help() {
    cat << 'EOF'
Claude Max Docker Automation - FIXED Authentication

This script uses your existing Claude Max subscription by creating 
writable copies of your authentication files.

USAGE:
    ./claude-max.sh [project-path] [task-file]

PREREQUISITES:
    1. Make sure you're logged into Claude Code on your Mac:
       claude --version  # Should work without asking for login
    
    2. Your Claude Max subscription should be active

EXAMPLES:
    ./claude-max.sh                                    # Current directory
    ./claude-max.sh /path/to/project                   # Specific project  
    ./claude-max.sh /path/to/project custom-tasks.md   # Custom task file

AUTHENTICATION FIX:
    ✅ Mounts authentication as read-only
    ✅ Creates writable copies inside container
    ✅ No more "read-only file system" errors
    ✅ Uses your Claude Max subscription

GIT FEATURES:
    ✅ Uses 'main' as default branch
    ✅ Creates feature branches automatically
    ✅ Proper commit management

The script will automatically verify your authentication before starting.
EOF
}

# Main function
case "${1:-start}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        start_session_with_auth "${1:-}" "${2:-CLAUDE_TASKS.md}"
        ;;
esac
