#!/bin/bash

# Solution: Don't exec into bash, just use the existing tmux windows

SESSION="claude-main"

echo "🚀 Opening Claude Code sessions (already running in containers)..."

# Profile mapping
get_profile() {
  case "$1" in
    *palladio*)   echo "Palladio" ;;
    *work*)       echo "Work" ;;
    *)            echo "Default" ;;
  esac
}

# Clean up clone sessions
tmux list-sessions -F '#{session_name}' | grep "^${SESSION}-" | while read s; do
  tmux kill-session -t "$s" 2>/dev/null || true
done

# The KEY INSIGHT: Your original tmux windows already show Claude Code
# They just got docker exec'd into bash. We need to exit bash first.

echo "Exiting bash shells to return to Claude Code..."
for i in {1..11}; do
  if tmux has-session -t "$SESSION:$i" 2>/dev/null; then
    # Send 'exit' to exit the bash shell
    tmux send-keys -t "$SESSION:$i" "exit" C-m
    sleep 0.2
  fi
done

echo "Waiting for Claude Code to appear..."
sleep 2

# Now create tabs
echo "Creating iTerm tabs..."
tmux list-windows -t "$SESSION" -F "#{window_index} #{window_name}" | while read -r idx name; do
  [[ "$idx" == "0" ]] && continue  # Skip dashboard
  
  # Create clone session
  CLONE="${SESSION}-${idx}"
  tmux new-session -d -s "$CLONE" -t "${SESSION}:${idx}"
  
  # Get profile
  profile=$(get_profile "$name")
  
  # Open iTerm tab
  osascript <<EOF
tell application "iTerm"
  tell current window
    create tab with profile "$profile"
    tell current session
      set name to "$name"
      write text "tmux attach -t $CLONE"
    end tell
  end tell
end tell
EOF
  
  sleep 0.3
done

echo "✅ Done! Each tab should now show Claude Code."
echo ""
echo "Note: If you still see bash prompts, manually type 'exit' in those tabs"
echo "to return to Claude Code."