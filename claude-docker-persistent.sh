#!/bin/bash

# Claude Docker Ephemeral Task Runner  
# Creates secure, auto-removing Docker containers for Claude Code execution
set -euo pipefail

# Source safety system for consistent logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/safety-system.sh" ]; then
    source "$SCRIPT_DIR/safety-system.sh"
fi

DOCKER_IMAGE="claude-automation:latest"
CONFIG_VOLUME="claude-code-config"
CONTAINER_PREFIX="claude-task"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }

# Get random icon for visual differentiation
get_task_icon() {
    # Array of colorful emoji icons for easy visual identification
    local icons=(
        "🔴"  # Red circle
        "🟠"  # Orange circle
        "🟡"  # Yellow circle
        "🟢"  # Green circle
        "🔵"  # Blue circle
        "🟣"  # Purple circle
        "🟤"  # Brown circle
        "⚫"  # Black circle
        "🔶"  # Orange diamond
        "🔷"  # Blue diamond
        "🔺"  # Red triangle
        "🔻"  # Red triangle down
        "🟦"  # Blue square
        "🟩"  # Green square
        "🟨"  # Yellow square
        "🟧"  # Orange square
        "🟪"  # Purple square
        "⭐"  # Star
        "💫"  # Dizzy star
        "🌟"  # Glowing star
        "✨"  # Sparkles
        "🎯"  # Target
        "🎨"  # Palette
        "🚀"  # Rocket
        "💎"  # Gem
        "🔮"  # Crystal ball
        "🎪"  # Circus tent
        "🎭"  # Theater masks
        "🎲"  # Dice
        "🎸"  # Guitar
    )
    
    # Generate random index based on current time and process ID
    local seed=$(( $(date +%s) + $$ ))
    local index=$(( seed % ${#icons[@]} ))
    
    echo "${icons[$index]}"
}

# Extract keywords from task content for container naming
extract_keywords() {
    local task_content="$1"
    local max_length=30
    
    # Extract meaningful words from task content
    # Remove markdown formatting, special chars, and common words
    local keywords=$(echo "$task_content" | \
        sed 's/[#*`_\[\]]//g' | \
        tr '[:upper:]' '[:lower:]' | \
        grep -o '\b[a-z]\{4,\}\b' | \
        grep -v -E '^(task|create|build|make|update|file|code|test|with|that|this|from|have|will|should|must|need)$' | \
        head -3 | \
        tr '\n' '-' | \
        sed 's/-$//')
    
    # Limit length and ensure valid Docker name
    echo "${keywords:0:$max_length}" | sed 's/[^a-z0-9-]//g'
}

# Setup config volume
setup_config_volume() {
    if ! docker volume inspect "$CONFIG_VOLUME" >/dev/null 2>&1; then
        log "Creating persistent config volume: $CONFIG_VOLUME"
        docker volume create "$CONFIG_VOLUME"
    fi
}

# Create persistent volume for project
create_project_volume() {
    local project_name="$1"
    local volume_name="claude-project-${project_name}"
    
    if ! docker volume inspect "$volume_name" >/dev/null 2>&1; then
        log "Creating project volume: $volume_name" >&2
        docker volume create "$volume_name" >/dev/null 2>&1
    fi
    
    echo "$volume_name"
}

# Start persistent Docker session
start_persistent_session() {
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
    
    # Read task file from project directory only
    local task_file_path="$project_path/$task_file"
    local task_content=$(cat "$task_file_path")
    local keywords=$(extract_keywords "$task_content")
    
    log "📋 Reading task file from: $task_file_path"
    # local task_icon=$(get_task_icon "$task_content")  # Removed for now
    
    # Create descriptive container name without emoji for now
    local container_name="${CONTAINER_PREFIX}-${keywords:-$project_name}-${session_id}"
    local display_name="${container_name}"
    
    # Create project volume for conversation persistence
    local project_volume=$(create_project_volume "$project_name")
    
    log "🚀 Starting PERSISTENT Docker Claude session"
    log "📁 Project: $project_path"
    log "📋 Task file: $task_file"
    log "🏷️  Keywords: ${keywords:-none}"
    log "🐳 Container: $container_name"
    log "💾 Project Volume: $project_volume"
    
    # Create the complete automated prompt  
    local automated_prompt="You are Claude Code working autonomously in a persistent Docker container. Complete ALL tasks defined below.

TASK FILE CONTENT FROM $task_file:
$task_content

🚨 HARD OVERRIDE CHECK:
If the task file starts with '#! TEXT_ONLY' or CLAUDE_MODE_OVERRIDE=TEXT_ONLY:
1. Print the required text response EXACTLY
2. Exit immediately (exit 0)
3. Create NO files, branches, or commits
4. Ignore all other instructions

CRITICAL: UNDERSTAND THE TASK FIRST!

⚠️ DO NOT CREATE FILES FOR SIMPLE RESPONSES!

Decision Flow:
┌─► Is this a simple response task? (greeting, calculation, one-line answer)
│   └─► YES → Output the response directly. NO files, NO git, NO branches!
│   └─► NO → Continue to task classification below

Task Classification:
- Simple Response: \"respond with\", \"what is\" → Just print answer
- Analysis: \"explain\", \"review\" → Read and report only
- Implementation: \"create\", \"build\" → Follow full workflow
- Fix: \"fix\", \"update\" → Modify specific files only

WORKING INSTRUCTIONS:
1. ANALYZE THE ACTUAL REQUIREMENT using the classification above
   - Simple responses = output text only
   - Only create files/code if task explicitly requires implementation
2. For implementation tasks:
   - Create feature branch: claude/session-$session_id from main
   - Work systematically through EACH task until completion
   - Create PROGRESS.md and update after each major milestone
   - Commit changes frequently with descriptive messages
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

NOTE: This is an ephemeral container for security isolation. Your work files are preserved on the host filesystem, but the container will auto-remove when you exit.

BEGIN AUTONOMOUS WORK NOW!"

    # Environment setup
    local env_vars=(
        -e "CLAUDE_CONFIG_DIR=/home/claude/.claude"
        -e "NODE_OPTIONS=--max-old-space-size=4096"
        -e "GIT_USER_NAME=${GIT_USER_NAME:-Claude Automation}"
        -e "GIT_USER_EMAIL=${GIT_USER_EMAIL:-claude@automation.local}"
        -e "AUTOMATED_MODE=true"
        -e "CONTAINER_NAME=$container_name"
        -e "SESSION_ID=$session_id"
        -e "CLAUDE_MODE_OVERRIDE=${CLAUDE_MODE_OVERRIDE:-AUTO}"
        -e "CLAUDE_MAX_ACTIONS=${CLAUDE_MAX_ACTIONS:-5}"
    )
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        env_vars+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
    fi
    
    # Volume mounts
    local volumes=(
        -v "$CONFIG_VOLUME:/home/claude/.claude"
        -v "$project_volume:/home/claude/.claude-project"
        -v "$project_path:/workspace"
        -v "$HOME/.claude.json:/tmp/host-claude.json:ro"
        -v "$HOME/.gitconfig:/tmp/.gitconfig:ro"
    )
    
    # Labels for better container management
    local labels=(
        --label "claude.project=$project_name"
        --label "claude.keywords=$keywords"
        --label "claude.session=$session_id"
        --label "claude.task_file=$task_file"
        --label "claude.icon=none"
        --label "claude.display_name=$container_name"
        --label "claude.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    )
    
    echo ""
    echo -e "${BLUE}🐳 SECURE DOCKER MODE${NC}"
    echo -e "${BLUE}═══════════════════════════${NC}"
    echo -e "${YELLOW}• Container will auto-remove after exit${NC}"
    echo -e "${YELLOW}• Secure isolation during execution${NC}"
    echo -e "${YELLOW}• Work files preserved on host filesystem${NC}"
    echo -e "${YELLOW}• No container clutter after completion${NC}"
    echo ""
    echo -e "${GREEN}Starting ephemeral container...${NC}"
    echo ""
    
    # Start container with auto-removal settings
    # Note: Using --rm flag ensures container is automatically removed after exit
    # This provides security isolation without persistent container clutter
    docker run -d \
        --name "$container_name" \
        --rm \
        "${env_vars[@]}" \
        "${volumes[@]}" \
        "${labels[@]}" \
        -w /workspace \
        --user claude \
        "$DOCKER_IMAGE" \
        bash -c "
            echo '🔧 Setting up persistent environment...'
            
            # Setup environment
            sudo chown -R claude:claude /home/claude/.claude 2>/dev/null || true
            sudo chown -R claude:claude /home/claude/.claude-project 2>/dev/null || true
            
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
            if [ -n \"${GITHUB_TOKEN:-}\" ]; then
                echo \"\$GITHUB_TOKEN\" | gh auth login --with-token 2>/dev/null || true
                echo '✅ GitHub CLI authenticated'
            fi
            
            # Save container metadata
            cat > /home/claude/.claude-project/container-info.json << EOF
{
    \"container_name\": \"$container_name\",
    \"session_id\": \"$session_id\",
    \"project_name\": \"$project_name\",
    \"keywords\": \"$keywords\",
    \"created\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
    \"task_file\": \"$task_file\"
}
EOF
            
            echo '🚀 Persistent environment ready'
            echo ''
            echo '📋 Task content:'
            echo '═══════════════════════════════════════'
            cat << 'AUTO_TASK_EOF'
$automated_prompt
AUTO_TASK_EOF
            echo '═══════════════════════════════════════'
            echo ''
            
            # Keep container running
            echo '🔄 Container is now persistent and running'
            echo 'Waiting for Claude Code to be started...'
            
            # Create marker file to indicate readiness
            touch /home/claude/.claude-project/ready
            
            # Keep container alive
            exec tail -f /dev/null
        "
    
    # Wait for container to be ready
    log "Waiting for container to initialize..."
    sleep 3
    
    # Check container status
    log "Checking if container '$container_name' is running..."
    if docker ps --filter "name=^${container_name}$" --format "{{.Names}}" | grep -q "^${container_name}$"; then
        echo ""
        log "✅ Persistent container created successfully!"
        echo ""
        echo -e "${BLUE}📊 Container Information:${NC}"
        echo "  Name: $container_name"
        echo "  Status: Running (persistent)"
        echo "  Restart Policy: no (won't auto-start)"
        echo "  Project Volume: $project_volume"
        echo "  Config Volume: $CONFIG_VOLUME"
        echo ""
        echo -e "${BLUE}🔧 Next Steps:${NC}"
        echo "  1. Attach to container: docker exec -it $container_name bash"
        echo "  2. Inside container run: claude --dangerously-skip-permissions"
        echo "  3. Paste the task when Claude starts"
        echo ""
        echo -e "${BLUE}📋 Management Commands:${NC}"
        echo "  View logs: docker logs $container_name"
        echo "  Stop: docker stop $container_name"
        echo "  Monitor: docker logs -f $container_name"
        echo "  Remove: docker rm -f $container_name"
        echo ""
        echo -e "${GREEN}💡 TIP:${NC} The container provides secure isolation and auto-cleans up!"
        
        # Save container info for later reference
        echo "$container_name" > "$HOME/.claude-last-container"
        
        # Auto-launch terminal to connect to the container
        launch_terminal_connection "$container_name" "$automated_prompt"
        
    else
        echo -e "${RED}Error:${NC} Container failed to start"
        docker logs "$container_name" 2>&1 | tail -20
        exit 1
    fi
}

# List persistent Claude containers
list_containers() {
    echo -e "${BLUE}📋 Persistent Claude Containers:${NC}"
    echo ""
    
    # Header
    printf "%-50s %-15s %-20s %-30s %-20s\n" "CONTAINER" "STATE" "PROJECT" "KEYWORDS" "CREATED"
    printf "%-50s %-15s %-20s %-30s %-20s\n" "$(printf '%.0s-' {1..50})" "$(printf '%.0s-' {1..15})" "$(printf '%.0s-' {1..20})" "$(printf '%.0s-' {1..30})" "$(printf '%.0s-' {1..20})"
    
    # List containers with icons
    docker ps -a --filter "label=claude.project" \
        --format "{{.Names}}|{{.State}}|{{.Label \"claude.project\"}}|{{.Label \"claude.keywords\"}}|{{.Label \"claude.created\"}}|{{.Label \"claude.icon\"}}" | \
    while IFS='|' read -r name state project keywords created icon; do
        # Use icon if available, otherwise default
        icon=${icon:-⚪}
        printf "%-50s %-15s %-20s %-30s %-20s\n" "$icon $name" "$state" "$project" "$keywords" "${created:0:19}"
    done
}

# Attach to last container
attach_last() {
    if [ -f "$HOME/.claude-last-container" ]; then
        local container_name=$(cat "$HOME/.claude-last-container")
        if docker ps | grep -q "$container_name"; then
            log "Attaching to $container_name..."
            docker exec -it "$container_name" bash
        else
            echo -e "${RED}Error:${NC} Container $container_name is not running"
        fi
    else
        echo -e "${RED}Error:${NC} No recent container found"
    fi
}

# Launch terminal connection to container
launch_terminal_connection() {
    local container_name="$1"
    local automated_prompt="$2"
    
    log "🖥️ Launching terminal connection to container..."
    
    # Get iTerm profile from environment or use default
    local iterm_profile="${CLAUDE_ITERM_PROFILE:-Default}"
    
    # Create a command that will connect to the container and start Claude
    local connect_command="docker exec -it '$container_name' bash -c \"cd /workspace && claude --dangerously-skip-permissions\""
    
    # Launch iTerm with the connection command
    if command -v osascript >/dev/null 2>&1; then
        log "🖥️ Launching iTerm terminal..."
        # Write the task content to a temp file for auto-injection
        local task_temp_file="/tmp/claude-task-${container_name}.txt"
        echo "$automated_prompt" > "$task_temp_file"
        
        # Create a temporary script file to avoid quoting issues
        local temp_script="/tmp/claude-connect-${container_name}.applescript"
        
        # Use container name directly as tab name (no emoji for now)
        local tab_name="${container_name}"
        
        # Check if we should open in new tab (default) or existing tab
        local open_new_tab="${CLAUDE_OPEN_NEW_TAB:-true}"
        
        log_event "DEBUG" "Docker mode detected. Open new tab: $open_new_tab"
        
        # Use direct AppleScript execution like tmux (avoiding temp file issues)
        if [ "$open_new_tab" = "true" ]; then
            log_event "DEBUG" "Attempting to open new iTerm tab..."
            if osascript -e "
            tell application \"iTerm\"
                activate
                if (count of windows) is 0 then
                    set targetWindow to (create window with profile \"$iterm_profile\")
                else
                    set targetWindow to current window
                    tell targetWindow
                        create tab with profile \"$iterm_profile\"
                    end tell
                end if
                
                tell targetWindow
                    tell last tab
                        tell current session
                            set name to \"$tab_name\"
                            write text \"echo '🐳 Connecting to Docker container: $container_name'\"
                            write text \"echo '🚀 Starting Claude Code...'\"
                            write text \"echo '💫 Task will be automatically injected in 10 seconds...'\"
                            write text \"echo ''\"
                            write text \"docker exec -it '$container_name' bash -c 'printf \\\"\\\\033]1;$tab_name\\\\007\\\" && printf \\\"\\\\033]0;$tab_name\\\\007\\\" && cd /workspace && claude --dangerously-skip-permissions'\"
                        end tell
                    end tell
                end tell
            end tell
            " 2>/dev/null; then
                log_event "DEBUG" "iTerm new tab created successfully"
            else
                log_event "WARN" "Failed to create iTerm new tab via AppleScript"
            fi
        else
            # Use existing tab behavior
            log_event "DEBUG" "Using existing tab mode"
            if osascript -e "
            tell application \"iTerm\"
                activate
                if (count of windows) is 0 then
                    set targetWindow to (create window with profile \"$iterm_profile\")
                else
                    set targetWindow to current window
                end if
                
                tell targetWindow
                    tell current session of current tab
                        set name to \"$tab_name\"
                        write text \"echo '🐳 Connecting to Docker container: $container_name'\"
                        write text \"echo '🚀 Starting Claude Code...'\"
                        write text \"echo '💫 Task will be automatically injected in 10 seconds...'\"
                        write text \"echo ''\"
                        write text \"docker exec -it '$container_name' bash -c 'printf \\\"\\\\033]1;$tab_name\\\\007\\\" && printf \\\"\\\\033]0;$tab_name\\\\007\\\" && cd /workspace && claude --dangerously-skip-permissions'\"
                    end tell
                end tell
            end tell
            " 2>/dev/null; then
                log_event "DEBUG" "iTerm existing tab used successfully"
            else
                log_event "WARN" "Failed to use existing iTerm tab via AppleScript"
            fi
        fi
        
        # Set up background task to auto-inject the task after 10 seconds
        {
            sleep 10  # Wait 10 seconds for Claude Code to initialize
            
            log "🤖 Auto-injecting task into Claude..."
            
            # Check if task file still exists
            if [ ! -f "$task_temp_file" ]; then
                log "⚠️  Task file not found, skipping auto-injection"
                return
            fi
            
            # Create AppleScript to paste the task content and press enter
            local paste_script="/tmp/claude-paste-${container_name}.applescript"
            
            # Use clipboard approach instead of trying to escape multi-line content
            # Copy task content to clipboard first, then paste it
            cat "$task_temp_file" | pbcopy
            
            cat > "$paste_script" << PASTE_EOF
tell application "iTerm"
    activate
    tell current session of current window
        -- Paste from clipboard using cmd+v
        tell application "System Events"
            key code 9 using command down
        end tell
        delay 1
        -- Press enter
        write text ""
    end tell
end tell
PASTE_EOF
            
            # Execute the paste script
            if osascript "$paste_script" 2>/dev/null; then
                log "✅ Task automatically injected into Claude!"
            else
                log "⚠️  Failed to inject task via AppleScript"
            fi
            
            # Clean up temp files
            rm -f "$paste_script" "$task_temp_file"
            
        } &  # Run in background
        
        log "✅ Terminal tab launched with profile: $iterm_profile"
    else
        # Fallback: just run the command
        echo "🔧 Running connection command directly..."
        echo "🐳 Connecting to Docker container: $container_name"
        echo "🚀 Starting Claude Code..."
        echo ""
        eval "$connect_command"
    fi
}

# Help
show_help() {
    cat << 'EOF'
Claude Docker Persistent Task Runner

USAGE:
    ./claude-docker-persistent.sh [command] [args]

COMMANDS:
    start [project-path] [task-file]    Start new persistent container
    list                                List all Claude containers
    attach                              Attach to last container
    help                                Show this help

FEATURES:
    • Creates persistent Docker containers
    • Smart container naming from task keywords
    • Restart policy: no (won't auto-start)
    • Conversation history preserved
    • Project-specific volumes
    • Auto-removes after completion

EXAMPLES:
    ./claude-docker-persistent.sh start                    # Current directory
    ./claude-docker-persistent.sh start /path/to/project   # Specific project
    ./claude-docker-persistent.sh list                     # List containers
    ./claude-docker-persistent.sh attach                   # Attach to last

CONTAINER NAMING:
    Containers are named: claude-task-[keywords]-[timestamp]
    Keywords are extracted from your task content for easy identification.
EOF
}

# Main
case "${1:-start}" in
    "start")
        start_persistent_session "${2:-}" "${3:-CLAUDE_TASKS.md}"
        ;;
    "list")
        list_containers
        ;;
    "attach")
        attach_last
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}Error:${NC} Unknown command: $1"
        show_help
        exit 1
        ;;
esac