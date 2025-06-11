#!/bin/bash

# Fix script - actually execute the docker commands in each window

SESSION="claude-main"

echo "🔧 Fixing tmux windows - executing docker commands..."

# For each window, send Enter to execute the waiting command
for i in {1..11}; do
  if tmux has-session -t "$SESSION:$i" 2>/dev/null; then
    echo "  Window $i: Sending Enter to execute docker command"
    tmux send-keys -t "$SESSION:$i" Enter
    sleep 0.5
  fi
done

echo "✅ Commands executed!"
echo ""
echo "Now run 'ca' again to open all tabs"