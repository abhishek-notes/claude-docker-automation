#!/bin/bash

# Bulletproof version - opens each session properly

echo "Opening Claude sessions in iTerm2 tabs..."

# Kill any existing attempts
pkill -f "tmux attach-session" 2>/dev/null || true

# Simple approach - just open tabs with the right commands
osascript << 'EOF'
tell application "iTerm"
    activate
    
    -- Create fresh window
    create window with default profile
    
    tell current window
        -- Tab 1: Palladio
        tell current session
            write text "echo 'Window 1: palladio-191408'; tmux attach -t claude-main; tmux select-window -t 1"
        end tell
        delay 0.5
        
        -- Tab 2: Work
        create tab with default profile
        tell current session
            write text "echo 'Window 2: work-070959'; tmux attach -t claude-main; tmux select-window -t 2"
        end tell
        delay 0.5
        
        -- Tab 3: Work
        create tab with default profile
        tell current session
            write text "echo 'Window 3: work-030125'; tmux attach -t claude-main; tmux select-window -t 3"
        end tell
        delay 0.5
        
        -- Tab 4: Work
        create tab with default profile
        tell current session
            write text "echo 'Window 4: work-161317'; tmux attach -t claude-main; tmux select-window -t 4"
        end tell
        delay 0.5
        
        -- Tab 5: Palladio
        create tab with default profile
        tell current session
            write text "echo 'Window 5: palladio-155426'; tmux attach -t claude-main; tmux select-window -t 5"
        end tell
        delay 0.5
        
        -- Continue for remaining windows...
        create tab with default profile
        tell current session
            write text "echo 'Window 6: claude-bob'; tmux attach -t claude-main; tmux select-window -t 6"
        end tell
        
        create tab with default profile
        tell current session
            write text "echo 'Window 7: claude-alice'; tmux attach -t claude-main; tmux select-window -t 7"
        end tell
        
        create tab with default profile
        tell current session
            write text "echo 'Window 8: automation'; tmux attach -t claude-main; tmux select-window -t 8"
        end tell
        
        create tab with default profile
        tell current session
            write text "echo 'Window 9: test-web'; tmux attach -t claude-main; tmux select-window -t 9"
        end tell
        
        create tab with default profile
        tell current session
            write text "echo 'Window 10: test-web'; tmux attach -t claude-main; tmux select-window -t 10"
        end tell
        
        create tab with default profile
        tell current session
            write text "echo 'Window 11: palladio-215205'; tmux attach -t claude-main; tmux select-window -t 11"
        end tell
    end tell
end tell
EOF

echo ""
echo "✅ Done! Each tab will attach to tmux and show instructions."
echo ""
echo "In each tab:"
echo "1. It will attach to tmux automatically"
echo "2. Press Ctrl-b then the window number shown"
echo "3. Press Enter to attach to Docker"