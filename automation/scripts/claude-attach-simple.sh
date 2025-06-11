#!/bin/bash

# Simple and reliable version to open all Claude sessions in tabs

TMUX_SESSION="claude-main"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to open all sessions in tabs
open_all_tabs() {
    echo -e "${BLUE}🚀 Opening all Claude sessions in separate iTerm2 tabs...${NC}"
    
    # Check tmux session exists
    if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        echo -e "${RED}No active tmux session found.${NC}"
        echo "Run: ~/Work/migrate-all-claude-sessions-enhanced.sh"
        exit 1
    fi
    
    # Get all windows
    tmux list-windows -t "$TMUX_SESSION" -F '#I:#W' | grep -v "dashboard" | while read window; do
        window_num=$(echo "$window" | cut -d: -f1)
        window_name=$(echo "$window" | cut -d: -f2)
        
        # Determine profile
        if [[ $window_name == *"palladio"* ]]; then
            profile="Palladio"
        elif [[ $window_name == *"automation"* ]]; then
            profile="Automation" 
        elif [[ $window_name == *"work"* ]]; then
            profile="Work"
        else
            profile="Default"
        fi
        
        echo "  Opening tab for: $window_name (window $window_num, profile: $profile)"
        
        # Open each in a new tab
        osascript - "$window_num" "$window_name" "$profile" << 'EOF'
on run argv
    set windowNum to item 1 of argv
    set windowName to item 2 of argv
    set profileName to item 3 of argv
    
    tell application "iTerm"
        tell current window
            create tab with profile profileName
            tell current session
                write text "tmux attach -t claude-main"
                delay 1
                write text windowNum
                delay 0.5
                send text "\r"
                set name to windowName
            end tell
        end tell
    end tell
end run
EOF
        
        sleep 1  # Give iTerm time to process
    done
    
    echo ""
    echo -e "${GREEN}✅ All sessions opened in separate tabs!${NC}"
}

# Simple attach for single window
attach_single() {
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        tmux attach-session -t "$TMUX_SESSION"
    else
        echo -e "${RED}No active tmux session found.${NC}"
    fi
}

# Main
case "${1:-all}" in
    "all")
        open_all_tabs
        ;;
    "single"|"s")
        attach_single
        ;;
    *)
        echo "Usage:"
        echo "  ca       - Open all sessions in tabs"
        echo "  ca s     - Single tmux window"
        ;;
esac