#!/bin/bash

# Final working solution - opens all Claude sessions in proper tabs

SESSION="claude-main"  # or claude-work if you created the new one

echo "🚀 Opening all Claude sessions in separate iTerm tabs..."

# Kill any existing tmux control mode sessions
tmux detach-client -a 2>/dev/null || true

# Function to determine profile
profile_for() {
  case "$1" in
    *palladio*)   echo "Palladio" ;;
    *work*)       echo "Work" ;;
    *automation*) echo "Automation" ;;
    *)            echo "Default" ;;
  esac
}

# Create the AppleScript
cat > /tmp/open_claude_tabs.scpt << 'SCRIPT_START'
tell application "iTerm"
    activate
    
    -- Create new window
    create window with default profile
    
    tell current window
SCRIPT_START

# Add each window as a tab
first_tab=true
tmux list-windows -t "$SESSION" -F "#{window_index} #{window_name}" | grep -v "dashboard" |
while read -r idx name; do
    profile=$(profile_for "$name")
    
    echo "  Creating tab for window $idx: $name"
    
    if [ "$first_tab" = true ]; then
        # First tab - use current tab
        cat >> /tmp/open_claude_tabs.scpt << EOF
        -- First tab: $name
        tell current session
            set name to "$name"
            write text "tmux attach-session -t $SESSION \\; select-window -t $idx"
        end tell
EOF
        first_tab=false
    else
        # Additional tabs
        cat >> /tmp/open_claude_tabs.scpt << EOF
        
        -- Tab for: $name
        set newTab to (create tab with profile "$profile")
        tell current session of newTab
            set name to "$name"
            write text "tmux attach-session -t $SESSION \\; select-window -t $idx"
        end tell
EOF
    fi
done

# Close the script
cat >> /tmp/open_claude_tabs.scpt << 'SCRIPT_END'
    end tell
end tell
SCRIPT_END

# Run the AppleScript
osascript /tmp/open_claude_tabs.scpt
rm -f /tmp/open_claude_tabs.scpt

echo ""
echo "✅ All sessions opened in separate tabs!"
echo ""
echo "Each tab:"
echo "  - Shows full terminal (not 25% panes)"
echo "  - Displays the correct Claude session"
echo "  - Has proper color coding"
echo "  - Press Enter to attach to Docker container"