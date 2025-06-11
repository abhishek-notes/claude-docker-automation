#!/bin/bash

# Enhanced Claude Docker Session with Better Authentication
# Handles Claude Max login and proper git setup

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

# Enhanced session start with better auth
start_session_enhanced() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    
    # Validate inputs
    if [ ! -d "$project_path" ]; then
        error "Project path does not exist: $project_path"
        exit 1
    fi
    
    if [ ! -f "$project_path/$task_file" ]; then
        error "Task file not found: $project_path/$task_file"
        exit 1
    fi
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "Starting enhanced Claude session: $container_name"
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
    
    # Add Anthropic API key if available
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        env_args+=(-e "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
        info "Using API key authentication"
    else
        warning "No API key - will use interactive authentication"
    fi
    
    # Add git configuration
    env_args+=(-e "GIT_USER_NAME=${GIT_USER_NAME:-Claude Automation}")
    env_args+=(-e "GIT_USER_EMAIL=${GIT_USER_EMAIL:-claude@automation.local}")
    
    # Mount configurations
    local mount_args=()
    
    # Mount git config
    if [ -f "$HOME/.gitconfig" ]; then
        mount_args+=(-v "$HOME/.gitconfig:/tmp/.gitconfig:ro")
    fi
    
    # Mount Claude Desktop config for Claude Max authentication
    local claude_desktop_config="$HOME/Library/Application Support/Claude"
    if [ -d "$claude_desktop_config" ]; then
        mount_args+=(-v "$claude_desktop_config:/tmp/claude-desktop:ro")
        info "Claude Max authentication enabled"
    fi
    
    # Enhanced session prompt
    local session_prompt="You are starting a task-completion based autonomous work session.

IMPORTANT SETUP INSTRUCTIONS:
1. First, run /login to authenticate if needed
2. If authentication fails, type 'exit' and we'll help you set it up
3. Once authenticated, read and complete ALL tasks in $task_file

WORK INSTRUCTIONS:
1. Create a feature branch: claude/session-$session_id from main branch
2. Work systematically through each task until completion
3. Create PROGRESS.md and update it after completing each major task
4. Commit changes frequently with meaningful messages
5. Test everything thoroughly as you build
6. Create comprehensive SUMMARY.md when ALL tasks are complete
7. Document any issues in ISSUES.md
8. Exit ONLY when all tasks are genuinely complete and working

GIT SETUP:
- Use 'main' as the default branch (not master)
- Create all new branches from main
- Never commit directly to main

You have full permissions in this Docker environment. Work until the job is done!"
    
    info "Starting container with enhanced authentication..."
    echo ""
    
    # Run container with enhanced setup
    docker run -it --rm \
        --name "$container_name" \
        "${env_args[@]}" \
        "${mount_args[@]}" \
        -v "$project_path:/workspace" \
        -w /workspace \
        $DOCKER_IMAGE \
        bash -c "
            echo '🔐 Setting up authentication...'
            
            # Try to authenticate automatically
            if [ -n \"\${ANTHROPIC_API_KEY:-}\" ]; then
                echo '✅ Using API key authentication'
                claude --dangerously-skip-permissions -p \"$session_prompt\"
            else
                echo '🔑 Starting interactive authentication...'
                echo 'Please follow these steps:'
                echo '1. Run: /login'
                echo '2. Follow the authentication prompts'
                echo '3. Once logged in, paste this prompt:'
                echo ''
                echo '$session_prompt'
                echo ''
                claude --dangerously-skip-permissions
            fi
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
}

# Show help for enhanced version
show_help_enhanced() {
    cat << 'EOF'
Enhanced Claude Docker Automation with Better Authentication

USAGE:
    ./claude-enhanced.sh [project-path] [task-file]

AUTHENTICATION OPTIONS:
    1. API Key (Recommended for automation):
       - Set ANTHROPIC_API_KEY in .env file
       - Fully autonomous operation
    
    2. Claude Max Interactive:
       - Use your Claude Max subscription
       - Interactive login in container
       - Inherits desktop authentication

EXAMPLES:
    ./claude-enhanced.sh                                    # Current directory
    ./claude-enhanced.sh /path/to/project                   # Specific project
    ./claude-enhanced.sh /path/to/project custom-tasks.md   # Custom task file

AUTHENTICATION SETUP:
    For API Key:
        echo 'export ANTHROPIC_API_KEY="your_key"' >> .env
    
    For Claude Max:
        Make sure you're logged into Claude Desktop

GIT IMPROVEMENTS:
    - Uses 'main' as default branch (not master)
    - Creates proper feature branches
    - Better branch naming conventions

The session will guide you through authentication if needed.
EOF
}

# Main function
case "${1:-start}" in
    "help"|"-h"|"--help")
        show_help_enhanced
        ;;
    *)
        start_session_enhanced "${1:-}" "${2:-CLAUDE_TASKS.md}"
        ;;
esac
