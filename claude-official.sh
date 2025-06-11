#!/bin/bash

# Claude Code Docker - Based on Official Devcontainer Setup
# This follows the exact patterns from anthropics/claude-code/.devcontainer

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

# Check if Docker image exists
check_image() {
    if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
        log "Building Docker image..."
        docker build -t "$DOCKER_IMAGE" .
    fi
}

# Create or check config volume
setup_config_volume() {
    if ! docker volume inspect "$CONFIG_VOLUME" >/dev/null 2>&1; then
        log "Creating persistent config volume: $CONFIG_VOLUME"
        docker volume create "$CONFIG_VOLUME"
    else
        log "Using existing config volume: $CONFIG_VOLUME"
    fi
}

# Start Claude with official-style setup
start_claude_session() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    
    # Validate project path
    if [ ! -d "$project_path" ]; then
        echo -e "${RED}Error:${NC} Project path does not exist: $project_path"
        exit 1
    fi
    
    # Setup
    check_image
    setup_config_volume
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "Starting Claude Code session: $container_name"
    log "Project: $project_path"
    
    # Environment variables (following official devcontainer pattern)
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
    
    # Volume mounts (following official pattern)
    local volumes=(
        # Persistent config volume (CRITICAL for avoiding setup prompts)
        -v "$CONFIG_VOLUME:/home/claude/.claude"
        
        # Project workspace
        -v "$project_path:/workspace"
        
        # Host Claude auth (read-only source)
        -v "$HOME/.claude.json:/tmp/host-claude.json:ro"
        
        # Git config
        -v "$HOME/.gitconfig:/tmp/.gitconfig:ro"
    )
    
    # Additional volumes for macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Claude Desktop config if available
        local claude_desktop_dir="$HOME/Library/Application Support/Claude"
        if [ -d "$claude_desktop_dir" ]; then
            volumes+=(-v "$claude_desktop_dir:/tmp/claude-desktop:ro")
        fi
    fi
    
    echo ""
    echo -e "${BLUE}🚀 Starting Claude Code with persistent configuration...${NC}"
    echo -e "${BLUE}📁 Project: $project_path${NC}"
    echo -e "${BLUE}💾 Config Volume: $CONFIG_VOLUME${NC}"
    echo ""
    
    # Run the container with official-style configuration
    docker run -it --rm \
        --name "$container_name" \
        "${env_vars[@]}" \
        "${volumes[@]}" \
        -w /workspace \
        --user claude \
        "$DOCKER_IMAGE" \
        bash -c '
            echo "🔧 Setting up Claude Code environment..."
            
            # Ensure config directory ownership
            sudo chown -R claude:claude /home/claude/.claude 2>/dev/null || true
            
            # Copy host authentication if needed and not already present
            if [ -f "/tmp/host-claude.json" ] && [ ! -f "/home/claude/.claude.json" ]; then
                echo "📋 Copying authentication from host..."
                cp /tmp/host-claude.json /home/claude/.claude.json
                chmod 600 /home/claude/.claude.json
            fi
            
            # Git configuration
            if [ -f "/tmp/.gitconfig" ]; then
                cp /tmp/.gitconfig /home/claude/.gitconfig
            fi
            git config --global init.defaultBranch main
            git config --global --add safe.directory /workspace
            
            # GitHub CLI auth if token available
            if [ -n "${GITHUB_TOKEN:-}" ]; then
                echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null || true
            fi
            
            echo "✅ Environment ready!"
            echo ""
            echo "Starting Claude Code..."
            echo "Note: First run may require authentication setup, but this will persist!"
            echo ""
            
            # Start Claude Code
            claude --dangerously-skip-permissions
        '
    
    echo ""
    log "Session completed: $container_name"
}

# Show volume info
show_volume_info() {
    echo -e "${BLUE}Claude Configuration Volume Status:${NC}"
    echo "=================================="
    
    if docker volume inspect "$CONFIG_VOLUME" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Volume exists: $CONFIG_VOLUME"
        
        # Check contents
        echo ""
        echo "Volume contents:"
        docker run --rm -v "$CONFIG_VOLUME:/check" alpine \
            sh -c 'ls -la /check/ 2>/dev/null || echo "Volume is empty"'
        
        # Check for key files
        echo ""
        echo "Configuration files:"
        docker run --rm -v "$CONFIG_VOLUME:/check" alpine \
            sh -c '
                [ -f /check/.claude.json ] && echo "✓ Authentication file exists" || echo "⚠ No authentication file"
                [ -d /check/settings ] && echo "✓ Settings directory exists" || echo "⚠ No settings directory"
            '
    else
        echo -e "${YELLOW}⚠${NC} Volume does not exist: $CONFIG_VOLUME"
        echo "Run './claude-official.sh start' to create it"
    fi
}

# Reset configuration
reset_config() {
    echo -e "${YELLOW}Resetting Claude configuration...${NC}"
    
    if docker volume inspect "$CONFIG_VOLUME" >/dev/null 2>&1; then
        docker volume rm "$CONFIG_VOLUME"
        echo -e "${GREEN}✓${NC} Configuration volume removed"
    fi
    
    echo "Next run will recreate the configuration from scratch"
}

# Help
show_help() {
    cat << 'EOF'
Claude Code Docker - Official Devcontainer Style

This script follows the patterns from the official Claude Code devcontainer
to ensure proper persistent configuration.

USAGE:
    ./claude-official.sh [command] [project-path] [task-file]

COMMANDS:
    start [path]  - Start Claude Code session (default)
    info          - Show volume information
    reset         - Reset configuration
    help          - Show this help

EXAMPLES:
    ./claude-official.sh start /Users/abhishek/Work/coin-flip-app
    ./claude-official.sh info
    ./claude-official.sh reset

FEATURES:
    ✅ Persistent configuration using Docker volumes
    ✅ Based on official devcontainer patterns
    ✅ Proper authentication handling
    ✅ Git integration
    ✅ No setup prompts after first run

The key is using a named Docker volume for /home/claude/.claude
which persists authentication and settings between container runs.
EOF
}

# Main
case "${1:-start}" in
    "start")
        start_claude_session "${2:-}" "${3:-CLAUDE_TASKS.md}"
        ;;
    "info")
        show_volume_info
        ;;
    "reset")
        reset_config
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        start_claude_session "${1:-}" "${2:-CLAUDE_TASKS.md}"
        ;;
esac