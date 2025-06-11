#!/bin/bash

# Better approach: Direct tmux window attachment

TMUX_SESSION="claude-main"

echo "🚀 Opening all Claude sessions in separate iTerm2 tabs..."

# Get window info
windows=$(tmux list-windows -t "$TMUX_SESSION" -F '#I:#W' 2>/dev/null | grep -v dashboard)

if [ -z "$windows" ]; then
    echo "No tmux windows found!"
    exit 1
fi

# Create AppleScript
cat > /tmp/open_claude_tabs.applescript << 'APPLESCRIPT_START'
tell application "iTerm"
    activate
    create window with default profile
    tell current window
APPLESCRIPT_START

# Add each window
first=true
while IFS= read -r window; do
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
    
    echo "  Adding tab for window $window_num: $window_name ($profile)"
    
    if [ "$first" = true ]; then
        # First tab - use current session
        cat >> /tmp/open_claude_tabs.applescript << APPLESCRIPT_TAB
        -- Window $window_num: $window_name
        tell current session
            set name to "$window_name"
            write text "tmux attach-session -t $TMUX_SESSION \\; select-window -t $window_num"
        end tell
APPLESCRIPT_TAB
        first=false
    else
        # Additional tabs
        cat >> /tmp/open_claude_tabs.applescript << APPLESCRIPT_TAB
        
        -- Window $window_num: $window_name
        create tab with profile "$profile"
        tell current session
            set name to "$window_name"
            write text "tmux attach-session -t $TMUX_SESSION \\; select-window -t $window_num"
        end tell
APPLESCRIPT_TAB
    fi
done <<< "$windows"

# Close AppleScript
cat >> /tmp/open_claude_tabs.applescript << 'APPLESCRIPT_END'
    end tell
end tell
APPLESCRIPT_END

# Run it
osascript /tmp/open_claude_tabs.applescript
rm -f /tmp/open_claude_tabs.applescript

echo ""
echo "✅ Opened $(echo "$windows" | wc -l) sessions in separate tabs!"
echo ""
echo "Each tab is connected to its specific tmux window."
echo "The window shows session history - press Enter to attach to Docker."