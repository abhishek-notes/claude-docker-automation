#!/usr/bin/env bash
# Opens each tmux window of claude-main in its own iTerm2 tab
# and maps window names to iTerm2 profiles.

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

# Get list: <index> <name>
tmux list-windows -t "$SESSION" -F "#{window_index} #{window_name}" |
while read -r idx name; do
  profile=$(profile_for "$name")
  echo "  Opening tab $idx: $name (Profile: $profile)"

  # AppleScript wrapper
  /usr/bin/osascript <<EOF
tell application "iTerm"
  -- Get or create window
  if (count of windows) = 0 then
    create window with default profile
  end if
  
  set myWindow to current window
  
  -- First tab uses current session, rest create new tabs
  if $idx = 0 then
    tell current session of myWindow
      write text "tmux attach -t $SESSION:$idx"
    end tell
  else
    tell myWindow
      create tab with profile "$profile"
      tell current session
        write text "tmux attach -t $SESSION:$idx"
      end tell
    end tell
  end if
end tell
EOF
  
  # Small delay between tabs
  sleep 0.5
done

echo ""
echo "✅ Opened all windows from $SESSION with color-coded profiles!"
echo ""
echo "Tips:"
echo "  • Each tab shows full history (up to your tmux history-limit)"
echo "  • Press Enter in any tab to attach to Docker"
echo "  • Use Cmd-1 through Cmd-9 to switch tabs"
echo "  • Close tabs with Cmd-W (containers keep running)"