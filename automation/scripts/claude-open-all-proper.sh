#!/bin/bash

# Properly open all Claude sessions in tabs with correct windows

TMUX_SESSION="claude-main"

echo "🚀 Opening all Claude sessions in separate iTerm2 tabs..."

# Create the AppleScript that properly navigates tmux
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
        delay 2
        tell application "System Events"
            key code 11 using control down -- Ctrl-b
            delay 0.5
            keystroke "w" -- Show window list
            delay 1
            keystroke "1" -- Select window 1
            delay 0.5
            key code 36 -- Enter
        end tell
        
        -- Window 2: work-070959
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 2
        tell application "System Events"
            key code 11 using control down -- Ctrl-b
            delay 0.5
            keystroke "2" -- Select window 2 directly
        end tell
        
        -- Window 3: work-030125
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 2
        tell application "System Events"
            key code 11 using control down -- Ctrl-b
            delay 0.5
            keystroke "3" -- Select window 3 directly
        end tell
        
        -- Window 4: work-161317
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 2
        tell application "System Events"
            key code 11 using control down -- Ctrl-b
            delay 0.5
            keystroke "4" -- Select window 4 directly
        end tell
        
        -- Window 5: palladio-155426
        create tab with profile "Palladio"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 2
        tell application "System Events"
            key code 11 using control down -- Ctrl-b
            delay 0.5
            keystroke "5" -- Select window 5 directly
        end tell
        
        -- Window 6: claude-bob
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 2
        tell application "System Events"
            key code 11 using control down -- Ctrl-b
            delay 0.5
            keystroke "6" -- Select window 6 directly
        end tell
        
        -- Window 7: claude-alice
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 2
        tell application "System Events"
            key code 11 using control down -- Ctrl-b
            delay 0.5
            keystroke "7" -- Select window 7 directly
        end tell
        
        -- Window 8: automation-145822
        create tab with profile "Automation"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 2
        tell application "System Events"
            key code 11 using control down -- Ctrl-b
            delay 0.5
            keystroke "8" -- Select window 8 directly
        end tell
        
        -- Window 9: test-web
        create tab with default profile
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 2
        tell application "System Events"
            key code 11 using control down -- Ctrl-b
            delay 0.5
            keystroke "9" -- Select window 9 directly
        end tell
        
        -- Window 10: test-web (need special handling for 2-digit numbers)
        create tab with default profile
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 2
        tell application "System Events"
            key code 11 using control down -- Ctrl-b
            delay 0.5
            keystroke "'" -- Quote key for entering window index
            delay 0.5
            keystroke "10"
            delay 0.5
            key code 36 -- Enter
        end tell
        
        -- Window 11: palladio-215205
        create tab with profile "Palladio"
        tell current session
            write text "tmux attach -t claude-main"
        end tell
        delay 2
        tell application "System Events"
            key code 11 using control down -- Ctrl-b
            delay 0.5
            keystroke "'" -- Quote key for entering window index
            delay 0.5
            keystroke "11"
            delay 0.5
            key code 36 -- Enter
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
echo "Each tab is now connected to its specific tmux window."
echo "Press Enter in any tab to attach to the Docker container."