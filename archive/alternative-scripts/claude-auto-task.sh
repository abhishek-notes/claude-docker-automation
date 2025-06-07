#!/bin/bash

# Claude Code with Automatic Task Execution
# Automatically accepts bypass permissions and starts working on tasks

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

# Check if task file exists, create if missing
check_or_create_task_file() {
    local project_path="$1"
    local task_file="$2"
    local full_path="$project_path/$task_file"
    
    if [ ! -f "$full_path" ]; then
        log "Task file not found: $task_file"
        echo -e "${YELLOW}Creating default task file...${NC}"
        
        cat > "$full_path" << 'EOF'
# Claude Autonomous Work Session

## Project Overview
Please analyze this project and help me with development tasks.

## Tasks
1. **Project Analysis**: Examine the codebase and understand the current state
2. **Identify Improvements**: Suggest areas for enhancement or bug fixes
3. **Implementation**: Implement the most valuable improvements
4. **Testing**: Ensure all changes work correctly
5. **Documentation**: Update any relevant documentation

## Technical Requirements
- Follow existing code patterns and conventions
- Create meaningful git commits for changes
- Handle errors gracefully
- Write tests if applicable

## Deliverables
- [ ] Complete project analysis
- [ ] Implemented improvements
- [ ] Updated documentation
- [ ] Summary of work completed

Please start by analyzing the project structure and suggesting what we should work on.
EOF
        
        log "✅ Created default task file: $task_file"
    else
        log "✅ Found task file: $task_file"
    fi
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

# Start Claude with automatic task execution
start_auto_task_session() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    
    # Validate project path
    if [ ! -d "$project_path" ]; then
        echo -e "${RED}Error:${NC} Project path does not exist: $project_path"
        exit 1
    fi
    
    # Check or create task file
    check_or_create_task_file "$project_path" "$task_file"
    
    # Setup volume
    setup_config_volume
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "Starting automated Claude session: $container_name"
    log "Project: $project_path"
    log "Task file: $task_file"
    
    # Environment variables
    local env_vars=(
        -e "CLAUDE_CONFIG_DIR=/home/claude/.claude"
        -e "NODE_OPTIONS=--max-old-space-size=4096"
        -e "GIT_USER_NAME=${GIT_USER_NAME:-Claude Automation}"
        -e "GIT_USER_EMAIL=${GIT_USER_EMAIL:-claude@automation.local}"
    )
    
    # Add GitHub token if available
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
    
    # Read task content for the prompt
    local task_content=$(cat "$project_path/$task_file")
    
    echo ""
    echo -e "${BLUE}🤖 Starting automated Claude Code session...${NC}"
    echo -e "${BLUE}📁 Project: $project_path${NC}"
    echo -e "${BLUE}📋 Task: $task_file${NC}"
    echo -e "${BLUE}🚀 Will automatically accept bypass permissions and start task${NC}"
    echo ""
    
    # Create the automated session
    docker run -it --rm \
        --name "$container_name" \
        "${env_vars[@]}" \
        "${volumes[@]}" \
        -w /workspace \
        --user claude \
        "$DOCKER_IMAGE" \
        bash -c "
            echo '🔧 Setting up Claude Code environment...'
            
            # Ensure config directory ownership
            sudo chown -R claude:claude /home/claude/.claude 2>/dev/null || true
            
            # Copy host authentication if needed
            if [ -f '/tmp/host-claude.json' ] && [ ! -f '/home/claude/.claude.json' ]; then
                echo '📋 Copying authentication from host...'
                cp /tmp/host-claude.json /home/claude/.claude.json
                chmod 600 /home/claude/.claude.json
            fi
            
            # Git configuration
            if [ -f '/tmp/.gitconfig' ]; then
                cp /tmp/.gitconfig /home/claude/.gitconfig
            fi
            git config --global init.defaultBranch main
            git config --global --add safe.directory /workspace
            
            # GitHub CLI auth if available
            if [ -n \"\${GITHUB_TOKEN:-}\" ]; then
                echo \"\$GITHUB_TOKEN\" | gh auth login --with-token 2>/dev/null || true
            fi
            
            echo '✅ Environment ready!'
            echo ''
            echo '🤖 Starting Claude Code with automatic task execution...'
            echo '⚡ This will auto-accept bypass permissions and start the task'
            echo ''
            
            # Create automated startup script
            cat > /tmp/auto-claude.exp << 'AUTOMATION_EOF'
#!/usr/bin/expect -f
set timeout 60

# Start Claude Code
spawn claude --dangerously-skip-permissions

# Wait for bypass permissions prompt and auto-accept
expect {
    \"1. No, exit\" {
        send \"2\\r\"
        exp_continue
    }
    \"2. Yes, I accept\" {
        send \"\\r\"
        exp_continue
    }
    \"Welcome to Claude Code\" {
        # Claude is ready, send the task
        sleep 2
        
        # Send the comprehensive task prompt
        send \"I need you to read and work on the tasks defined in $task_file. Here's what I need you to do:\\r\\r\"
        send \"TASK CONTENT:\\r\"
        send \"$task_content\\r\\r\"
        send \"INSTRUCTIONS:\\r\"
        send \"1. Create a feature branch: claude/session-$session_id from main\\r\"
        send \"2. Work systematically through each task until completion\\r\"
        send \"3. Create PROGRESS.md and update it after each major task\\r\"
        send \"4. Commit changes frequently with meaningful messages\\r\"
        send \"5. Test everything thoroughly\\r\"
        send \"6. Create SUMMARY.md when all tasks are complete\\r\"
        send \"7. Document any issues in ISSUES.md\\r\\r\"
        send \"Please start by analyzing the project and then begin working on the tasks. Work autonomously until all tasks are complete!\\r\"
        
        # Hand control back to user (or let Claude work)
        interact
    }
    timeout {
        puts \"Timeout waiting for Claude prompt\"
        exit 1
    }
}
AUTOMATION_EOF
            
            # Install expect and run automation
            sudo apt-get update -qq && sudo apt-get install -y -qq expect >/dev/null 2>&1 || {
                echo '⚠️  Could not install expect, falling back to manual mode'
                echo '📋 Please manually:'
                echo '   1. Press 2 + Enter to accept bypass permissions'
                echo '   2. Then paste this task:'
                echo ''
                echo \"Read and work on tasks in $task_file. Create feature branch claude/session-$session_id, work systematically through tasks, create PROGRESS.md, commit frequently, and create SUMMARY.md when complete.\"
                echo ''
                claude --dangerously-skip-permissions
                exit 0
            }
            
            chmod +x /tmp/auto-claude.exp
            echo '🎯 Starting automated Claude session...'
            /tmp/auto-claude.exp
        "
    
    echo ""
    log "Automated session completed: $container_name"
    
    # Show results
    show_session_results "$project_path"
}

# Show session results
show_session_results() {
    local project_path="$1"
    
    echo ""
    echo -e "${BLUE}📊 Session Results:${NC}"
    echo "=================="
    
    # Check for result files
    local result_files=("PROGRESS.md" "SUMMARY.md" "ISSUES.md")
    for file in "${result_files[@]}"; do
        if [ -f "$project_path/$file" ]; then
            echo -e "${GREEN}✓${NC} $file created"
        else
            echo -e "${YELLOW}⚠${NC} $file not found"
        fi
    done
    
    # Git status if available
    if [ -d "$project_path/.git" ]; then
        echo ""
        echo -e "${BLUE}📋 Git Status:${NC}"
        cd "$project_path"
        git status --short 2>/dev/null || echo "No git repository"
        
        echo ""
        echo -e "${BLUE}📝 Recent Commits:${NC}"
        git log --oneline -5 2>/dev/null || echo "No commits"
        
        echo ""
        echo -e "${BLUE}🌿 Claude Branches:${NC}"
        git branch -a 2>/dev/null | grep claude || echo "No Claude branches"
    fi
    
    # Show summary if available
    if [ -f "$project_path/SUMMARY.md" ]; then
        echo ""
        echo -e "${BLUE}📄 Summary Preview:${NC}"
        head -10 "$project_path/SUMMARY.md"
        echo ""
        echo "Full summary: $project_path/SUMMARY.md"
    fi
}

# Help
show_help() {
    cat << 'EOF'
Claude Code with Automatic Task Execution

This script automatically accepts bypass permissions and starts Claude
working on your defined tasks without manual intervention.

USAGE:
    ./claude-auto-task.sh [project-path] [task-file]

FEATURES:
    ✅ Automatic bypass permissions acceptance
    ✅ Auto-starts task execution
    ✅ Creates default task file if missing
    ✅ Persistent configuration (no setup prompts)
    ✅ Comprehensive task instructions
    ✅ Git branch management
    ✅ Progress tracking

EXAMPLES:
    ./claude-auto-task.sh /Users/abhishek/Work/coin-flip-app
    ./claude-auto-task.sh . my-tasks.md
    ./claude-auto-task.sh /path/to/project

WORKFLOW:
    1. Creates/finds task file
    2. Starts Claude with persistent config
    3. Auto-accepts bypass permissions
    4. Sends comprehensive task instructions
    5. Claude works autonomously until complete
    6. Shows results summary

If task file doesn't exist, creates a default one asking Claude
to analyze the project and suggest improvements.
EOF
}

# Main
case "${1:-start}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        start_auto_task_session "${1:-}" "${2:-CLAUDE_TASKS.md}"
        ;;
esac