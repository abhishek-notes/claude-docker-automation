#!/bin/bash

# Simple tmux -CC approach for iTerm2

echo "🚀 Opening Claude sessions using iTerm2's native tmux integration..."
echo ""
echo "This will create a new window with all tmux windows as tabs."
echo ""

# Check if inside tmux already
if [ -n "$TMUX" ]; then
    echo "⚠️  You're already in tmux. Please exit first (Ctrl-b d)"
    exit 1
fi

# Use iTerm2's control mode
tmux -CC attach -t claude-main

echo ""
echo "✅ To detach: Close the iTerm2 window or press Cmd-D"