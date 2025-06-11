#!/usr/bin/env bash
# Working solution without tmux -CC
SESSION="claude-main"

# map window name → profile
profile_for() {
  case "$1" in
    palladio*)   echo "Palladio" ;;
    work*)       echo "Work" ;;
    automation*) echo "Automation" ;;
    *)           echo "Default" ;;
  esac
}

echo "🚀 Opening Claude sessions in separate tabs..."

# First, make sure we're not in tmux
if [ -n "$TMUX" ]; then
    echo "Please exit tmux first (Ctrl-b d)"
    exit 1
fi

# Create new iTerm window
/usr/bin/osascript <<'EOF'
tell application "iTerm"
  create window with default profile
end tell
EOF

sleep 1

# Skip dashboard (window 0), start from window 1
tmux list-windows -t "$SESSION" -F "#{window_index} #{window_name}" | grep -v "^0 " |
while read -r idx name; do
  profile=$(profile_for "$name")
  echo "  Opening window $idx: $name (Profile: $profile)"

  /usr/bin/osascript <<EOF
tell application "iTerm"
  tell current window
    create tab with profile "$profile"
    tell current session
      write text "tmux attach -t ${SESSION}:${idx}"
    end tell
  end tell
end tell
EOF
  
  sleep 0.5
done

echo "✅ Opened all windows from $SESSION"
echo ""
echo "Each tab is attached to its specific tmux window."
echo "Press Enter in any tab to attach to the Docker container."