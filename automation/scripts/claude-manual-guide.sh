#!/bin/bash

echo "Manual steps to open all sessions:"
echo ""
echo "1. In iTerm2, press Cmd+T to create a new tab"
echo "2. Run: tmux attach -t claude-main"  
echo "3. Press Ctrl-b then 1 (for first window)"
echo "4. Repeat for each window (2, 3, 4... up to 11)"
echo ""
echo "Or run this to at least get started:"

osascript -e 'tell application "iTerm" to activate'
osascript -e 'tell application "iTerm" to create window with default profile'

echo ""
echo "Window opened. Now in each tab run:"
echo "  tmux attach -t claude-main"
echo "  Ctrl-b [number]"