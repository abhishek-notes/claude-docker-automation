#!/bin/bash

# Simple working solution - just attach to existing windows

SESSION="claude-main"

echo "🚀 Opening Claude sessions..."

# Check if session exists
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "❌ No tmux session found. Run cleanup-and-rebuild.sh first"
  exit 1
fi

# For the first window, just attach normally
echo "Opening main tmux window..."
osascript <<EOF
tell application "iTerm"
  create window with default profile
  tell current session of current window
    write text "tmux attach -t $SESSION"
  end tell
end tell
EOF

sleep 2

echo ""
echo "✅ Opened tmux session!"
echo ""
echo "Navigation:"
echo "  • Press Ctrl-b w to see all windows"
echo "  • Use arrows to select"
echo "  • Press Enter to switch"
echo "  • Each window shows its Docker container"
echo ""
echo "For multiple tabs (if needed):"
echo "  • Cmd+T for new tab"
echo "  • Run: tmux attach -t $SESSION"
echo "  • Then Ctrl-b and window number"