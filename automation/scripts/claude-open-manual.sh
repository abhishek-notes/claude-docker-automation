#!/bin/bash

# Ultra-simple manual version

echo "Opening all Claude sessions in tabs..."
echo ""
echo "Your tmux windows:"
tmux list-windows -t claude-main -F '#I: #W' | grep -v dashboard
echo ""
echo "To open each in a tab:"
echo "1. Cmd+T (new tab)"
echo "2. Type: ca s"
echo "3. Press Ctrl-b then the window number"
echo ""
echo "Or try the automated version:"

osascript << 'EOF'
tell application "iTerm"
    activate
    create window with default profile
    
    tell current window
        -- Palladio 1
        create tab with profile "Palladio"
        tell current session
            write text "tmux attach -t claude-main -c 'select-window -t 1'"
        end tell
        
        -- Work sessions
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main -c 'select-window -t 2'"
        end tell
        
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main -c 'select-window -t 3'"
        end tell
    end tell
end tell
EOF