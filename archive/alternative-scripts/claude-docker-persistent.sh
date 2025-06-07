#!/bin/bash

# Claude Docker with Persistent Configuration
# This version maintains Claude settings between runs

set -euo pipefail

DOCKER_IMAGE="claude-automation:latest"
VOLUME_NAME="claude-config-volume"
CONTAINER_PREFIX="claude-session"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Create persistent volume if it doesn't exist
create_persistent_volume() {
    if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
        log "Creating persistent volume for Claude configuration..."
        docker volume create "$VOLUME_NAME"
        
        # Initialize the volume with pre-configured settings
        docker run --rm \
            -v "$VOLUME_NAME:/claude-config" \
            -v "$HOME/.claude.json:/tmp/.claude.json:ro" \
            $DOCKER_IMAGE \
            bash -c '
                # Create Claude directories
                mkdir -p /claude-config/.claude
                mkdir -p /claude-config/.anthropic
                mkdir -p /claude-config/.config
                
                # Copy authentication if available
                if [ -f "/tmp/.claude.json" ]; then
                    cp /tmp/.claude.json /claude-config/.claude.json
                    chmod 600 /claude-config/.claude.json
                fi
                
                # Pre-configure Claude to skip setup
                cat > /claude-config/.claude/settings.json << "EOF"
{
  "setupComplete": true,
  "firstRun": false,
  "hasShownWelcome": true,
  "telemetryEnabled": false,
  "theme": "dark",
  "editor": {
    "theme": "dark"
  }
}
EOF
                
                # Create Claude preferences
                cat > /claude-config/.claude/preferences.json << "EOF"
{
  "theme": "dark",
  "setupComplete": true,
  "skipWelcome": true,
  "agreedToTerms": true
}
EOF
                
                # Create config directory structure
                mkdir -p /claude-config/.config/claude-code
                
                # Set permissions
                chmod -R 700 /claude-config/.claude
                chmod -R 700 /claude-config/.config
            '
        
        log "✅ Persistent volume initialized with Claude configuration"
    else
        log "✅ Using existing Claude configuration volume"
    fi
}

# Start session with persistent config
start_persistent_session() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    
    # Validate inputs
    if [ ! -d "$project_path" ]; then
        error "Project path does not exist: $project_path"
        exit 1
    fi
    
    # Create persistent volume
    create_persistent_volume
    
    # Get session info
    local project_name=$(basename "$project_path")
    local session_id="$(date +%Y%m%d-%H%M%S)"
    local container_name="${CONTAINER_PREFIX}-${project_name}-${session_id}"
    
    log "Starting Claude with persistent configuration"
    log "Project: $project_path"
    
    # Build environment variables
    local env_args=()
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        env_args+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
    fi
    env_args+=(-e "GIT_USER_NAME=${GIT_USER_NAME:-Claude Automation}")
    env_args+=(-e "GIT_USER_EMAIL=${GIT_USER_EMAIL:-claude@automation.local}")
    
    # Mount arguments including persistent volume
    local mount_args=()
    
    # Mount persistent config volume
    mount_args+=(-v "$VOLUME_NAME:/home/claude/.claude-persistent")
    
    # Mount current Claude auth if available
    if [ -f "$HOME/.claude.json" ]; then
        mount_args+=(-v "$HOME/.claude.json:/home/claude/.claude.json.host:ro")
    fi
    
    # Mount project workspace
    mount_args+=(-v "$project_path:/workspace")
    
    # Mount git config
    if [ -f "$HOME/.gitconfig" ]; then
        mount_args+=(-v "$HOME/.gitconfig:/tmp/.gitconfig:ro")
    fi
    
    info "Starting Docker container with persistent Claude configuration..."
    echo ""
    
    # Start the container with persistent config
    docker run -it --rm \
        --name "$container_name" \
        "${env_args[@]}" \
        "${mount_args[@]}" \
        -w /workspace \
        $DOCKER_IMAGE \
        bash -c '
            # Link persistent config to Claude directories
            echo "🔧 Setting up persistent configuration..."
            
            # Create symlinks to persistent storage
            if [ -d "/home/claude/.claude-persistent/.claude" ]; then
                rm -rf /home/claude/.claude
                ln -s /home/claude/.claude-persistent/.claude /home/claude/.claude
            fi
            
            if [ -f "/home/claude/.claude-persistent/.claude.json" ]; then
                ln -sf /home/claude/.claude-persistent/.claude.json /home/claude/.claude.json
            elif [ -f "/home/claude/.claude.json.host" ]; then
                cp /home/claude/.claude.json.host /home/claude/.claude-persistent/.claude.json
                ln -sf /home/claude/.claude-persistent/.claude.json /home/claude/.claude.json
                chmod 600 /home/claude/.claude-persistent/.claude.json
            fi
            
            if [ -d "/home/claude/.claude-persistent/.config" ]; then
                rm -rf /home/claude/.config
                ln -s /home/claude/.claude-persistent/.config /home/claude/.config
            fi
            
            # Git setup
            git config --global init.defaultBranch main
            git config --global --add safe.directory /workspace
            
            echo "✅ Persistent configuration loaded"
            echo ""
            echo "Starting Claude Code..."
            echo "Your configuration is preserved between sessions!"
            echo ""
            
            # Start Claude
            claude --dangerously-skip-permissions
        '
    
    log "Session completed"
}

# Show volume info
show_volume_info() {
    echo -e "${BLUE}Claude Configuration Volume Info:${NC}"
    echo "================================"
    
    if docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Volume exists: $VOLUME_NAME"
        
        # Show volume details
        local volume_path=$(docker volume inspect "$VOLUME_NAME" --format '{{ .Mountpoint }}')
        echo "  Path: $volume_path"
        
        # Check what's in the volume
        docker run --rm -v "$VOLUME_NAME:/check" alpine ls -la /check/ 2>/dev/null || true
    else
        echo -e "${YELLOW}⚠${NC} Volume does not exist yet"
        echo "  It will be created on first run"
    fi
}

# Reset volume (for troubleshooting)
reset_volume() {
    echo -e "${YELLOW}Resetting Claude configuration volume...${NC}"
    docker volume rm "$VOLUME_NAME" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Volume reset. Configuration will be recreated on next run."
}

# Main function
case "${1:-start}" in
    "start")
        start_persistent_session "${2:-}" "${3:-CLAUDE_TASKS.md}"
        ;;
    "info")
        show_volume_info
        ;;
    "reset")
        reset_volume
        ;;
    "help"|"-h"|"--help")
        cat << 'EOF'
Claude Docker with Persistent Configuration

This version maintains Claude settings between container runs,
so you don't have to go through setup every time.

USAGE:
    ./claude-docker-persistent.sh start [project-path] [task-file]
    ./claude-docker-persistent.sh info
    ./claude-docker-persistent.sh reset
    ./claude-docker-persistent.sh help

COMMANDS:
    start - Start Claude with persistent config (default)
    info  - Show volume information
    reset - Reset configuration (start fresh)
    help  - Show this help

FEATURES:
    ✅ Persistent Claude configuration between runs
    ✅ No theme selection on subsequent runs
    ✅ Maintains authentication state
    ✅ Preserves your preferences

EXAMPLES:
    ./claude-docker-persistent.sh start /path/to/project
    ./claude-docker-persistent.sh info
    ./claude-docker-persistent.sh reset  # If you need to start fresh
EOF
        ;;
    *)
        start_persistent_session "${1:-}" "${2:-CLAUDE_TASKS.md}"
        ;;
esac