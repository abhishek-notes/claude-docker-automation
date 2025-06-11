#!/usr/bin/env bash

# Claude Code Docker Session Manager with tmux
# This script launches Claude Code in Docker containers within tmux sessions
# that survive terminal crashes and system reboots

# Color codes for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TMUX_SESSION="claude-main"
CLAUDE_IMAGE="ghcr.io/anthropics/claude-code:latest"

# Function to create tmux config if it doesn't exist
setup_tmux_config() {
    if [ ! -f ~/.tmux.conf ]; then
        echo -e "${BLUE}Creating optimized tmux config...${NC}"
        cat > ~/.tmux.conf << 'EOF'
# Enable mouse support
set -g mouse on

# Increase scrollback buffer
set -g history-limit 100000

# Better status bar
set -g status-interval 5
set -g status-bg colour234
set -g status-fg colour137
set -g status-left '#[fg=colour233,bg=colour245,bold] #S '
set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '

# Window status
setw -g window-status-format " #I:#W#F "
setw -g window-status-current-format " #I:#W#F "
setw -g window-status-current-style bg=colour238,fg=colour81,bold

# Don't rename windows automatically
setw -g automatic-rename off

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Better key bindings
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"
bind | split-window -h
bind - split-window -v
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Enable activity alerts
setw -g monitor-activity on
set -g visual-activity on
EOF
        echo -e "${GREEN}tmux config created!${NC}"
    fi
}

# Function to launch Claude Code in a new tmux window
launch_claude() {
    local TASK_NAME="${1:-claude-task}"
    local PROJECT_DIR="${2:-$(pwd)}"
    local WINDOW_NAME="$TASK_NAME-$(date +%H%M%S)"
    
    shift 2 # Remove first two args, pass rest to docker
    
    # Ensure tmux session exists
    tmux has-session -t "$TMUX_SESSION" 2>/dev/null || \
        tmux new-session -d -s "$TMUX_SESSION" -n "dashboard"
    
    # Create new window for this Claude instance
    echo -e "${BLUE}Launching Claude Code for: ${YELLOW}$TASK_NAME${NC}"
    echo -e "${BLUE}Project directory: ${YELLOW}$PROJECT_DIR${NC}"
    
    tmux new-window -t "$TMUX_SESSION" -n "$WINDOW_NAME" -c "$PROJECT_DIR" \
        "docker run --rm \
            --name claude-session-${TASK_NAME}-$(date +%Y%m%d-%H%M%S) \
            -v '$PROJECT_DIR:/home/user/project' \
            -v ~/.gitconfig:/home/user/.gitconfig:ro \
            -v claude-code-config:/home/user/.config/claude-code \
            -e CLAUDE_PROJECT_DIR='/home/user/project' \
            $CLAUDE_IMAGE $*; \
            echo ''; \
            echo 'Claude Code session ended. Press any key to close...'; \
            read -n 1"
    
    # Switch to the new window
    tmux select-window -t "$TMUX_SESSION:$WINDOW_NAME"
    
    # Attach to session if not already in tmux
    if [ -z "$TMUX" ]; then
        tmux attach-session -t "$TMUX_SESSION"
    else
        echo -e "${GREEN}New Claude window created: ${WINDOW_NAME}${NC}"
    fi
}

# Function to list all active Claude sessions
list_sessions() {
    echo -e "${BLUE}=== Active Claude tmux Windows ===${NC}"
    tmux list-windows -t "$TMUX_SESSION" 2>/dev/null | grep -v "dashboard" | \
        awk '{print "  " $1 " " $2}' | sed 's/:/ -/'
    
    echo -e "\n${BLUE}=== Running Claude Docker Containers ===${NC}"
    docker ps --filter "name=claude" --format "table {{.Names}}\t{{.Status}}\t{{.Command}}" | \
        head -10
}

# Function to attach to existing session
attach_session() {
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        tmux attach-session -t "$TMUX_SESSION"
    else
        echo -e "${RED}No active Claude tmux session found.${NC}"
        echo -e "${YELLOW}Start a new one with: $0 launch <task-name> [project-dir]${NC}"
    fi
}

# Function to kill a specific window
kill_window() {
    local WINDOW_ID="$1"
    if [ -z "$WINDOW_ID" ]; then
        echo -e "${RED}Please specify a window number or name${NC}"
        list_sessions
        return 1
    fi
    
    tmux kill-window -t "$TMUX_SESSION:$WINDOW_ID"
    echo -e "${GREEN}Killed window: $WINDOW_ID${NC}"
}

# Main command dispatcher
case "${1:-help}" in
    "launch"|"start"|"new")
        setup_tmux_config
        launch_claude "${2:-claude-task}" "${3:-$(pwd)}" "${@:4}"
        ;;
    
    "attach"|"a")
        attach_session
        ;;
    
    "list"|"ls")
        list_sessions
        ;;
    
    "kill")
        kill_window "$2"
        ;;
    
    "dashboard"|"d")
        if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
            tmux new-window -t "$TMUX_SESSION" -n "monitor" \
                "watch -n 2 'docker ps --filter name=claude --format \"table {{.Names}}\t{{.Status}}\" | head -20'"
            tmux select-window -t "$TMUX_SESSION:monitor"
            [ -z "$TMUX" ] && tmux attach-session -t "$TMUX_SESSION"
        else
            echo -e "${RED}No active session. Start one first.${NC}"
        fi
        ;;
    
    "setup")
        setup_tmux_config
        echo -e "${GREEN}Setup complete!${NC}"
        echo -e "${YELLOW}Quick start guide:${NC}"
        echo "  1. Launch Claude: $0 launch my-task /path/to/project"
        echo "  2. List sessions: $0 list"
        echo "  3. Reattach:     $0 attach"
        echo "  4. Dashboard:    $0 dashboard"
        ;;
    
    *)
        echo -e "${BLUE}Claude Code Docker Session Manager${NC}"
        echo ""
        echo "Usage:"
        echo "  $0 launch <task-name> [project-dir] [docker-args]  - Start new Claude session"
        echo "  $0 attach                                          - Reattach to tmux session"
        echo "  $0 list                                            - List all active sessions"
        echo "  $0 kill <window-id>                                - Kill specific window"
        echo "  $0 dashboard                                       - Live container monitor"
        echo "  $0 setup                                           - Configure tmux"
        echo ""
        echo "Examples:"
        echo "  $0 launch palladio ~/Work/palladio-software-25"
        echo "  $0 launch web-scraper ~/Projects/scraper --env DEBUG=1"
        echo ""
        echo "tmux shortcuts (inside session):"
        echo "  Ctrl-b d     - Detach (leave running)"
        echo "  Ctrl-b w     - List/switch windows"
        echo "  Ctrl-b &     - Kill current window"
        echo "  Ctrl-b [     - Enter scroll mode (q to exit)"
        ;;
esac