#!/bin/bash

# Working version to open all Claude sessions in tabs

TMUX_SESSION="claude-main"

echo "🚀 Opening all Claude sessions in separate iTerm2 tabs..."

# First, let's see what we have
echo ""
echo "Your active sessions:"
tmux list-windows -t "$TMUX_SESSION" -F '#I: #W' 2>/dev/null | grep -v dashboard || {
    echo "No tmux session found!"
    exit 1
}

# Create the AppleScript
cat > /tmp/open_all_claude_tabs.applescript << 'APPLESCRIPT'
tell application "iTerm"
    activate
    
    -- Create new window
    create window with default profile
    
    tell current window
        -- Window 1: palladio-191408
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 1
        tell current session
            write text "1"
        end tell
        
        -- Window 2: work-070959
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 1
        tell current session
            write text "2"
        end tell
        
        -- Window 3: work-030125
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 1
        tell current session
            write text "3"
        end tell
        
        -- Window 4: work-161317
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 1
        tell current session
            write text "4"
        end tell
        
        -- Window 5: palladio-155426
        create tab with profile "Palladio"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 1
        tell current session
            write text "5"
        end tell
        
        -- Window 6: claude-bob
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 1
        tell current session
            write text "6"
        end tell
        
        -- Window 7: claude-alice
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 1
        tell current session
            write text "7"
        end tell
        
        -- Window 8: automation-145822
        create tab with profile "Automation"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 1
        tell current session
            write text "8"
        end tell
        
        -- Window 9: test-web
        create tab with default profile
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 1
        tell current session
            write text "9"
        end tell
        
        -- Window 10: test-web
        create tab with default profile
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 1
        tell current session
            write text "10"
        end tell
        
        -- Window 11: palladio-215205
        create tab with profile "Palladio"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 1
        tell current session
            write text "11"
        end tell
    end tell
end tell
APPLESCRIPT

# Run the AppleScript
osascript /tmp/open_all_claude_tabs.applescript
rm -f /tmp/open_all_claude_tabs.applescript

echo ""
echo "✅ All 11 sessions should now be open in separate tabs!"
echo ""
echo "Each tab shows the session details with history."
echo "Press Enter in any tab to attach to the Docker container."
echo ""
echo "Tab navigation:"
echo "  • Cmd+1 through Cmd+9 - Jump to tabs 1-9"
echo "  • Cmd+Shift+[ or ] - Previous/Next tab"