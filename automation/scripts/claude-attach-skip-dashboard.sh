#!/usr/bin/env bash
# Opens each tmux window of claude-main in its own iTerm2 tab
# SKIPS the dashboard (window 0)

SESSION="claude-main"

# Map tmux-window-name substrings → iTerm2 profile name
profile_for() {
  case "$1" in
    palladio*) echo "Palladio" ;;
    work*)     echo "Work" ;;
    automation*|cleaner*) echo "Automation" ;;
    claude-bob|claude-alice) echo "Work" ;;
    *)         echo "Default" ;;
  esac
}

echo "🎨 Opening color-coded tabs for all Claude sessions..."

# First, let's see what windows we have
echo "Found windows:"
tmux list-windows -t "$SESSION" -F "#{window_index} #{window_name}" | grep -v "dashboard"

# Get list EXCLUDING dashboard (window 0)
first_tab=true
tmux list-windows -t "$SESSION" -F "#{window_index} #{window_name}" | grep -v "dashboard" |
while read -r idx name; do
  profile=$(profile_for "$name")
  echo "  Opening tab for window $idx: $name (Profile: $profile)"

  # AppleScript wrapper
  if [ "$first_tab" = true ]; then
    # First non-dashboard window - use current window
    /usr/bin/osascript <<EOF
tell application "iTerm"
  if (count of windows) = 0 then
    create window with default profile
  end if
  
  tell current session of current window
    write text "tmux attach -t $SESSION:$idx"
  end tell
end tell
EOF
    first_tab=false
  else
    # Additional tabs
    /usr/bin/osascript <<EOF
tell application "iTerm"
  tell current window
    create tab with profile "$profile"
    tell current session
      write text "tmux attach -t $SESSION:$idx"
    end tell
  end tell
end tell
EOF
  fi
  
  # Small delay between tabs
  sleep 0.5
done

echo ""
echo "✅ Opened all Claude windows (skipped dashboard)!"
echo ""
echo "Tips:"
echo "  • Each tab shows your Claude session"
echo "  • Press Enter to attach to the Docker container"
echo "  • Use Cmd-1 through Cmd-9 to switch tabs"