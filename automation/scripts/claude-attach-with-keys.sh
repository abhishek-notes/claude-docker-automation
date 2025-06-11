#!/usr/bin/env bash

# Different approach: Attach first, then send window selection

SESSION="claude-main"

# Map window names to profiles
profile_for() {
  case "$1" in
    palladio*) echo "Palladio" ;;
    work*)     echo "Work" ;;
    automation*) echo "Automation" ;;
    *) echo "Default" ;;
  esac
}

echo "🎨 Opening Claude sessions with proper window selection..."

# Create new window
/usr/bin/osascript <<'EOF'
tell application "iTerm"
  create window with default profile
end tell
EOF

sleep 1

# Process each window (skip dashboard)
tmux list-windows -t "$SESSION" -F "#{window_index} #{window_name}" | grep -v "^0 " |
while read -r idx name; do
  profile=$(profile_for "$name")
  echo "  Opening window $idx: $name"
  
  if [ "$idx" = "1" ]; then
    # First window - use current tab
    /usr/bin/osascript <<EOF
tell application "iTerm"
  tell current session of current window
    -- Attach to tmux
    write text "tmux attach -t claude-main"
    delay 2
    -- Send Ctrl-b
    tell application "System Events"
      key code 11 using control down
    end tell
    delay 0.5
    -- Send window number
    write text "$idx"
  end tell
end tell
EOF
  else
    # Create new tab
    /usr/bin/osascript <<EOF
tell application "iTerm"
  tell current window
    create tab with profile "$profile"
    tell current session
      -- Attach to tmux
      write text "tmux attach -t claude-main"
      delay 2
      -- Send Ctrl-b
      tell application "System Events"
        key code 11 using control down
      end tell
      delay 0.5
      -- Send window number
      write text "$idx"
    end tell
  end tell
end tell
EOF
  fi
  
  sleep 2
done

echo ""
echo "✅ All windows should now be open in separate tabs"
echo ""
echo "Note: Each tab attached to tmux and then switched to its window"