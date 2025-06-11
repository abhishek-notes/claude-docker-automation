#!/bin/bash

# Fix for dashboard overwriting all tabs

echo "🛑 Stopping the dashboard temporarily..."

# Send Ctrl-C to the dashboard window to stop the loop
tmux send-keys -t claude-main:0 C-c
sleep 1

# Send a simple command that doesn't refresh
tmux send-keys -t claude-main:0 "echo 'Dashboard paused. Press up arrow and Enter to restart.'" Enter

echo "✅ Dashboard stopped"
echo ""
echo "Now try running ca again - the tabs should work properly!"
echo ""
echo "To restart the dashboard later:"
echo "1. Go to the dashboard tab"
echo "2. Press up arrow and Enter"