#!/bin/bash

# Debug what's happening with tmux windows

echo "=== Debugging tmux windows ==="
echo ""

# Check if tmux session exists
if ! tmux has-session -t claude-main 2>/dev/null; then
    echo "❌ No tmux session 'claude-main' found!"
    exit 1
fi

echo "✅ tmux session 'claude-main' exists"
echo ""

# List all windows with details
echo "Current tmux windows:"
tmux list-windows -t claude-main -F "#I: #W (active: #{window_active})"
echo ""

# Test attaching to specific windows
echo "Testing direct window attachment..."
echo "Try these commands manually:"
echo ""
echo "1. For window 1 (palladio):"
echo "   tmux attach-session -t claude-main -c \"#{session_id}:1\""
echo ""
echo "2. Alternative syntax:"
echo "   tmux attach -t claude-main:1"
echo ""
echo "3. Using new-session approach:"
echo "   tmux new-session -t claude-main:1"
echo ""

# Show current attached clients
echo "Currently attached clients:"
tmux list-clients
echo ""

# Try the simplest working approach
echo "=== SOLUTION ==="
echo "Use this command format in the script:"
echo 'tmux new-session -d -s temp-$idx -t claude-main:$idx \; attach -t temp-$idx'