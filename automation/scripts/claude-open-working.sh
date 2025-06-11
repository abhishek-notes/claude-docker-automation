#!/bin/bash

# Simple working version to open all Claude sessions

TMUX_SESSION="claude-main"

echo "🚀 Opening all Claude sessions in separate iTerm2 tabs..."

# Method 1: Direct command for each window
osascript << 'EOF'
tell application "iTerm"
    activate
    
    -- Create new window
    create window with default profile
    
    tell current window
        -- Window 1: palladio-191408
        tell current session
            write text "tmux attach-session -t claude-main && tmux select-window -t 1"
        end tell
        
        -- Window 2: work-070959
        create tab with profile "Work"
        tell current session
            write text "tmux attach-session -t claude-main && tmux select-window -t 2"
        end tell
        
        -- Window 3: work-030125
        create tab with profile "Work"
        tell current session
            write text "tmux attach-session -t claude-main && tmux select-window -t 3"
        end tell
        
        -- Window 4: work-161317
        create tab with profile "Work"
        tell current session
            write text "tmux attach-session -t claude-main && tmux select-window -t 4"
        end tell
        
        -- Window 5: palladio-155426
        create tab with profile "Palladio"
        tell current session
            write text "tmux attach-session -t claude-main && tmux select-window -t 5"
        end tell
        
        -- Window 6: claude-bob
        create tab with profile "Work"
        tell current session
            write text "tmux attach-session -t claude-main && tmux select-window -t 6"
        end tell
        
        -- Window 7: claude-alice
        create tab with profile "Work"
        tell current session
            write text "tmux attach-session -t claude-main && tmux select-window -t 7"
        end tell
        
        -- Window 8: automation-145822
        create tab with profile "Automation"
        tell current session
            write text "tmux attach-session -t claude-main && tmux select-window -t 8"
        end tell
        
        -- Window 9: test-web
        create tab with default profile
        tell current session
            write text "tmux attach-session -t claude-main && tmux select-window -t 9"
        end tell
        
        -- Window 10: test-web
        create tab with default profile
        tell current session
            write text "tmux attach-session -t claude-main && tmux select-window -t 10"
        end tell
        
        -- Window 11: palladio-215205
        create tab with profile "Palladio"
        tell current session
            write text "tmux attach-session -t claude-main && tmux select-window -t 11"
        end tell
    end tell
end tell
EOF

echo ""
echo "✅ All 11 sessions opened in separate tabs!"
echo ""
echo "Note: If windows show 'can't find session', just run in each tab:"
echo "  tmux attach -t claude-main"
echo "  Then press Ctrl-b followed by the window number (1-11)"