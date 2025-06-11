#!/usr/bin/env bash
# Simple solution - just attach to existing Claude sessions

SESSION="claude-main"

# Profile mapping
get_profile() {
  local name="$1"
  case "${name}" in
    *palladio*)   echo "Palladio" ;;
    *work*)       echo "Work" ;;
    *)            echo "Default" ;;
  esac
}

echo "🚀 Opening existing Claude sessions..."

# Check if session exists
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "❌ No tmux session '$SESSION' found!"
  exit 1
fi

# Clean up old clone sessions
echo "Cleaning up old sessions..."
tmux list-sessions -F '#{session_name}' | grep "^${SESSION}-" | while read s; do
  tmux kill-session -t "$s" 2>/dev/null || true
done

# Create new iTerm window
echo "Creating new iTerm window..."

# Process each window
tmux list-windows -t "$SESSION" -F "#{window_index} #{window_name}" | while read -r idx name; do
  [[ "$idx" == "0" ]] && continue  # Skip dashboard
  
  echo "  Processing window $idx: $name"
  
  # Create clone session
  CLONE="${SESSION}-${idx}"
  tmux new-session -d -s "$CLONE" -t "${SESSION}:${idx}"
  
  # Get profile
  profile=$(get_profile "$name")
  
  # Open iTerm tab and attach
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

echo "✅ Done! Each tab now shows its Claude Code session."
echo ""
echo "Tips:"
echo "  • Each tab shows the existing Claude Code interface"
echo "  • Use Ctrl-p Ctrl-q to detach from Docker if needed"
echo "  • The conversation history is preserved"