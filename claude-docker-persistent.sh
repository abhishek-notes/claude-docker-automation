#!/bin/bash

# Claude Docker Persistent Task Runner
# Creates persistent Docker containers with proper naming and restart policies
set -euo pipefail

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
        log "Creating project volume: $volume_name"
        docker volume create "$volume_name"
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
    local task_content=$(cat "$project_path/$task_file")
    local keywords=$(extract_keywords "$task_content")
    local task_icon=$(get_task_icon "$task_content")
    
    # Create descriptive container name with icon
    # Note: Docker names can't contain emoji, so we'll use icon in labels and display
    local container_name="${CONTAINER_PREFIX}-${keywords:-$project_name}-${session_id}"
    local display_name="${task_icon} ${container_name}"
    
    # Create project volume for conversation persistence
    local project_volume=$(create_project_volume "$project_name")
    
    log "🚀 Starting PERSISTENT Docker Claude session"
    log "📁 Project: $project_path"
    log "📋 Task file: $task_file"
    log "🏷️  Keywords: ${keywords:-none}"
    log "🐳 Container: $display_name"
    log "💾 Project Volume: $project_volume"
    
    # Create the complete automated prompt
    local automated_prompt="You are Claude Code working autonomously in a persistent Docker container. Complete ALL tasks defined below.

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

NOTE: This is a persistent container. Your work and conversation will be preserved even after container restarts.

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
        --label "claude.icon=$task_icon"
        --label "claude.display_name=$display_name"
        --label "claude.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    )
    
    echo ""
    echo -e "${BLUE}🐳 PERSISTENT DOCKER MODE${NC}"
    echo -e "${BLUE}═══════════════════════════${NC}"
    echo -e "${YELLOW}• Container will persist after exit${NC}"
    echo -e "${YELLOW}• Restart policy: no (preserved but won't auto-start)${NC}"
    echo -e "${YELLOW}• Conversation history preserved${NC}"
    echo -e "${YELLOW}• Named volumes for data persistence${NC}"
    echo ""
    echo -e "${GREEN}Starting persistent container...${NC}"
    echo ""
    
    # Start container with persistence settings
    # Note: NOT using --rm flag ensures container is preserved after exit
    # restart=no means it won't auto-start on Docker startup (but still preserved)
    docker run -d \
        --name "$container_name" \
        --restart no \
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
            if [ -n \"\${GITHUB_TOKEN:-}\" ]; then
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
    if docker ps | grep -q "$container_name"; then
        echo ""
        log "✅ Persistent container created successfully!"
        echo ""
        echo -e "${BLUE}📊 Container Information:${NC}"
        echo "  Name: $display_name"
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
        echo "  Restart: docker restart $container_name"
        echo "  Remove: docker rm -f $container_name"
        echo ""
        echo -e "${GREEN}💡 TIP:${NC} The container will persist across Docker restarts!"
        
        # Save container info for later reference
        echo "$container_name" > "$HOME/.claude-last-container"
        
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
    • Survives Docker restarts

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