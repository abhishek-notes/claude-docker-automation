#!/bin/bash

# Open all Claude sessions in separate iTerm2 tabs

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
    
    # Get all tmux windows (excluding dashboard)
    windows=$(tmux list-windows -t "$TMUX_SESSION" 2>/dev/null | grep -v "dashboard" | awk -F: '{print $1":"$2}')
    
    if [ -z "$windows" ]; then
        echo -e "${RED}No active sessions found in tmux.${NC}"
        echo "Run the migration script first: ~/Work/migrate-all-claude-sessions-enhanced.sh"
        exit 1
    fi
    
    # Count windows
    window_count=$(echo "$windows" | wc -l)
    echo -e "${GREEN}Found $window_count active sessions${NC}"
    echo ""
    
    # Build complete AppleScript
    applescript="tell application \"iTerm\"
    activate
    
    -- Get current window or create new one
    if (count of windows) = 0 then
        create window with default profile
    end if
    
    tell current window"
    
    # Process each window
    while IFS= read -r window; do
        window_num=$(echo "$window" | cut -d: -f1)
        window_name=$(echo "$window" | cut -d: -f2 | cut -d' ' -f1)
        
        # Determine profile based on window name
        if [[ $window_name == *"palladio"* ]]; then
            profile="Palladio"
            emoji="🏛️"
        elif [[ $window_name == *"automation"* ]]; then
            profile="Automation"
            emoji="🤖"
        elif [[ $window_name == *"work"* ]]; then
            profile="Work"
            emoji="💼"
        elif [[ $window_name == "claude-alice" ]] || [[ $window_name == "claude-bob" ]]; then
            profile="Work"
            emoji="👥"
        else
            profile="Default"
            emoji="📁"
        fi
        
        echo "  Opening tab for: $emoji $window_name (Profile: $profile)"
        
        # Add to AppleScript
        applescript="$applescript
        
        -- Create tab for $window_name
        create tab with profile \"$profile\"
        tell current session
            set name to \"$emoji $window_name\"
            write text \"tmux attach -t $TMUX_SESSION\"
            delay 0.5
            write text \"$window_num\"
            delay 0.5
            key code 36 -- Press Enter to select window
        end tell"
        
    done <<< "$windows"
    
    # Close the AppleScript
    applescript="$applescript
    end tell
end tell"
    
    # Execute the AppleScript
    osascript -e "$applescript"
    
    echo ""
    echo -e "${GREEN}✅ All sessions opened in separate tabs!${NC}"
    echo ""
    echo -e "${YELLOW}Tips:${NC}"
    echo "  • Each tab is color-coded by project type"
    echo "  • Each tab will auto-connect to its tmux window"
    echo "  • Press Enter in any tab to attach to that Docker session"
    echo "  • Use Cmd+Shift+[ or ] to switch between tabs"
    echo "  • Use Cmd+1,2,3... to jump to specific tabs"
    echo "  • Close a tab with Cmd+W (container keeps running)"
}

# Function to open specific session type
open_by_type() {
    local session_type="$1"
    
    case "$session_type" in
        "palladio"|"p")
            pattern="palladio"
            profile="Palladio"
            ;;
        "work"|"w")
            pattern="work"
            profile="Work"
            ;;
        "automation"|"a")
            pattern="automation"
            profile="Automation"
            ;;
        *)
            echo "Unknown type: $session_type"
            echo "Use: palladio/p, work/w, or automation/a"
            exit 1
            ;;
    esac
    
    echo -e "${BLUE}Opening all $pattern sessions...${NC}"
    
    # Get filtered windows
    windows=$(tmux list-windows -t "$TMUX_SESSION" 2>/dev/null | grep "$pattern" | awk -F: '{print $1":"$2}')
    
    if [ -z "$windows" ]; then
        echo -e "${YELLOW}No $pattern sessions found.${NC}"
        exit 1
    fi
    
    # Similar logic to open_all_tabs but filtered
    window_count=$(echo "$windows" | wc -l)
    echo -e "${GREEN}Found $window_count $pattern sessions${NC}"
    
    # Use same AppleScript approach...
    echo "Implementation coming..."
}

# Function to attach to single tmux session
attach_single() {
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        tmux attach-session -t "$TMUX_SESSION"
    else
        echo -e "${RED}No active tmux session found.${NC}"
    fi
}

# Main dispatcher
case "${1:-all}" in
    "all")
        open_all_tabs
        ;;
    "palladio"|"p")
        open_by_type "palladio"
        ;;
    "work"|"w")
        open_by_type "work"
        ;;
    "automation"|"a")
        open_by_type "automation"
        ;;
    "single"|"s")
        attach_single
        ;;
    "help"|"-h")
        echo "Claude Session Attach (ca) - Enhanced"
        echo ""
        echo "Usage:"
        echo "  ca          - Open ALL sessions in separate tabs (default)"
        echo "  ca single   - Attach to tmux session (single window)"
        echo "  ca s        - Short for 'ca single'"
        echo "  ca palladio - Open all Palladio sessions in tabs"
        echo "  ca work     - Open all Work sessions in tabs"
        echo "  ca auto     - Open all Automation sessions in tabs"
        echo ""
        echo "Shortcuts:"
        echo "  ca p        - Same as 'ca palladio'"
        echo "  ca w        - Same as 'ca work'"
        echo "  ca a        - Same as 'ca automation'"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use 'ca help' for usage"
        ;;
esac