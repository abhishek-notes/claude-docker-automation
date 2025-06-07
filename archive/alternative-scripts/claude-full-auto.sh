#!/bin/bash

# Fully Automated Claude Launcher - Zero Interaction
# Automatically accepts all prompts and starts with task

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

# Check authentication
check_claude_auth() {
    if [ ! -f "$HOME/.claude.json" ]; then
        error "Claude authentication not found at ~/.claude.json"
        echo "Please run 'claude' on your Mac first to authenticate"
        exit 1
    fi
    log "✅ Claude Max authentication ready"
}

# Start fully automated session
start_automated_session() {
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
    
    check_claude_auth
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "Starting automated Claude session: $container_name"
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
    
    # Mount arguments
    local mount_args=()
    mount_args+=(-v "$HOME/.claude.json:/home/claude/.claude.json.readonly:ro")
    
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
    
    # Read the task file content
    local task_content=$(cat "$project_path/$task_file")
    
    info "Starting container with full automation..."
    echo ""
    echo -e "${YELLOW}🤖 Claude will work completely autonomously${NC}"
    echo -e "${YELLOW}📊 Monitor: tail -f $project_path/PROGRESS.md${NC}"
    echo ""
    
    # Start container with automation script
    docker run -it --rm \
        --name "$container_name" \
        "${env_args[@]}" \
        "${mount_args[@]}" \
        -v "$project_path:/workspace" \
        -w /workspace \
        $DOCKER_IMAGE \
        bash -c "
            echo '🚀 Setting up automated Claude session...'
            
            # Create automation script that handles all prompts
            cat > /tmp/claude-automation.exp << 'AUTOMATION_EOF'
#!/usr/bin/expect -f

set timeout 300
set task_content {$task_content}

# Start Claude Code
spawn claude --dangerously-skip-permissions

# Handle bypass permissions prompt
expect {
    \"1. No, exit\" {
        send \"2\\r\"
        exp_continue
    }
    \"2. Yes, I accept\" {
        send \"\\r\"
        exp_continue
    }
    \"❯ 2. Yes, I accept\" {
        send \"\\r\"
        exp_continue
    }
    \"Welcome to Claude Code\" {
        # We're in! Now send the task
        sleep 2
        send \"Please read and complete all tasks in CLAUDE_TASKS.md. Work systematically through each task until completion. Create PROGRESS.md and update it regularly. Create SUMMARY.md when all tasks are complete. Use main branch and create feature branches for work. Begin now.\\r\"
        expect \">\"
        # Let Claude work autonomously
        interact
    }
    timeout {
        puts \"Timeout waiting for Claude prompt\"
        exit 1
    }
}
AUTOMATION_EOF

            chmod +x /tmp/claude-automation.exp
            
            # Install expect if not available
            apt-get update -qq && apt-get install -y -qq expect || true
            
            # Run the automation
            echo '🤖 Starting automated Claude session...'
            /tmp/claude-automation.exp
        "
    
    # Post-session results
    echo ""
    log "Automated session completed: $container_name"
    show_results "$project_path"
}

# Show results
show_results() {
    local project_path="$1"
    
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
    
    # Git status
    if [ -d "$project_path/.git" ]; then
        echo ""
        echo -e "${BLUE}📋 Git Status:${NC}"
        cd "$project_path"
        git status --short
        echo ""
        echo -e "${BLUE}📝 Recent Commits:${NC}"
        git log --oneline -5 2>/dev/null || echo "No commits yet"
    fi
    
    # Show summary if available
    if [ -f "$project_path/SUMMARY.md" ]; then
        echo ""
        echo -e "${BLUE}📄 Session Summary:${NC}"
        head -10 "$project_path/SUMMARY.md"
        echo ""
        echo "Full summary: $project_path/SUMMARY.md"
    fi
}

# Alternative simpler approach - direct automation
start_simple_automation() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    
    check_claude_auth
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "Starting simple automation: $container_name"
    
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
    
    echo ""
    echo -e "${YELLOW}🤖 Starting simple automation mode${NC}"
    echo -e "${YELLOW}You'll need to:${NC}"
    echo -e "${YELLOW}1. Press '2' then Enter to accept bypass permissions${NC}"
    echo -e "${YELLOW}2. Then Claude will get the task automatically${NC}"
    echo ""
    
    # Use a simpler approach with automatic task injection
    docker run -it --rm \
        --name "$container_name" \
        "${env_args[@]}" \
        "${mount_args[@]}" \
        -v "$project_path:/workspace" \
        -w /workspace \
        $DOCKER_IMAGE \
        bash -c "
            echo '🚀 Starting Claude with task injection...'
            
            # Create a script that will send the task after Claude starts
            cat > /tmp/send-task.sh << 'TASK_EOF'
#!/bin/bash
sleep 5
echo 'Sending task to Claude...'
# This would ideally send the task to Claude's stdin
# For now, we'll let the user manually paste the task
TASK_EOF
            
            chmod +x /tmp/send-task.sh
            
            # Start Claude and immediately provide the task
            echo 'Starting Claude Code...'
            echo 'After accepting bypass permissions, paste this task:'
            echo '---'
            echo 'Please read and complete all tasks in CLAUDE_TASKS.md. Work systematically through each task until completion. Create PROGRESS.md and update it regularly. Create SUMMARY.md when all tasks are complete. Use main branch and create feature branches for work. Begin now.'
            echo '---'
            
            claude --dangerously-skip-permissions
        "
    
    show_results "$project_path"
}

# Show help
show_help() {
    cat << 'EOF'
Fully Automated Claude Launcher

USAGE:
    ./claude-full-auto.sh [project-path] [task-file]
    ./claude-full-auto.sh simple [project-path] [task-file]

MODES:
    default - Full automation with expect scripts
    simple  - Simple mode with task injection

EXAMPLES:
    ./claude-full-auto.sh /path/to/project
    ./claude-full-auto.sh simple /path/to/project
EOF
}

# Main function
case "${1:-default}" in
    "simple")
        start_simple_automation "${2:-}" "${3:-CLAUDE_TASKS.md}"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        start_simple_automation "${1:-}" "${2:-CLAUDE_TASKS.md}"
        ;;
esac
