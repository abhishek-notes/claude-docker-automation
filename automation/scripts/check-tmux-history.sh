#!/bin/bash

# Script to check and increase tmux history for all panes

echo "🔍 Checking tmux history settings..."

# Show current history limit
echo "Current global history limit:"
tmux show-options -g | grep history-limit

echo ""
echo "Setting higher history limit..."

# Set a very high history limit
tmux set-option -g history-limit 100000

echo "✅ History limit set to 100,000 lines"
echo ""

# Show history for each pane
echo "Current history in each window:"
tmux list-windows -t claude-main -F '#I: #W' | while read window; do
    idx=$(echo $window | cut -d: -f1)
    name=$(echo $window | cut -d: -f2-)
    
    # Get pane info
    lines=$(tmux capture-pane -t claude-main:$idx -p | wc -l)
    echo "Window $idx ($name): $lines lines in buffer"
done

echo ""
echo "To see MORE history from Docker containers:"
echo ""
echo "1. In any tmux window, detach from Docker first:"
echo "   Ctrl-p Ctrl-q"
echo ""
echo "2. Then check the container's full logs:"
echo "   docker logs --tail 10000 <container-name> | less"
echo ""
echo "3. Or save to file:"
echo "   docker logs --tail 10000 <container-name> > session-history.txt"