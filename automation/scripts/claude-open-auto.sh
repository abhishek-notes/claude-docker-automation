#!/usr/bin/env bash
# Open every window of "claude-main" in its own iTerm2 tab & profile
# UPDATED: Automatically attaches to Docker containers

BASE=claude-main

profile_for() {                    # map window-name → iTerm2 profile
  case "$1" in
    palladio*)   echo "Palladio" ;;
    work*)       echo "Work"     ;;
    automation*) echo "Automation" ;;
    *)           echo "Default"  ;;
  esac
}

echo "🚀 Opening Claude sessions with automatic Docker attachment..."

# First ensure base session exists
if ! tmux has-session -t "$BASE" 2>/dev/null; then
  echo "❌ Base session '$BASE' not found. Run migration script first."
  exit 1
fi

# Get list of containers for mapping
declare -A window_to_container
window_num=1
for container in $(docker ps --filter name=claude --format '{{.Names}}'); do
  window_to_container[$window_num]=$container
  ((window_num++))
done

# Count windows
window_count=$(tmux list-windows -t "$BASE" -F "#{window_index}" | grep -v "^0$" | wc -l)
echo "Found $window_count Claude windows (excluding dashboard)"

tmux list-windows -t "$BASE" -F "#{window_index} #{window_name}" |
while read -r idx name; do
  [ "$idx" = "0" ] && continue    # skip the dashboard

  newsess="${BASE}-${idx}"
  container="${window_to_container[$idx]}"
  
  echo "  Creating session for window $idx: $name → $container"
  
  # create one tiny session per window (only once)
  session_exists=false
  if tmux has-session -t "$newsess" 2>/dev/null; then
    session_exists=true
  else
    tmux new-session -d -s "$newsess" -t "$BASE:$idx"
  fi
  
  # If this is a fresh session, automatically run docker exec
  if [ "$session_exists" = false ] && [ -n "$container" ]; then
    echo "    Auto-attaching to container: $container"
    tmux send-keys -t "$newsess:0.0" C-m  # Clear any existing prompt
    tmux send-keys -t "$newsess:0.0" "docker exec -it $container /bin/bash" C-m
  fi

  # open an iTerm2 tab and attach that session **in control mode**
  osascript <<EOF
tell application "iTerm"
  tell current window
    create tab with profile "$(profile_for "$name")"
    tell current session
      set name to "$name"
      write text "tmux -CC attach -t $newsess"
    end tell
  end tell
end tell
EOF
  
  sleep 0.5  # Small delay between tabs
done

echo "✅ Opened $window_count Claude tabs!"
echo ""
echo "Each tab:"
echo "  • Shows its own Claude window"
echo "  • Has the correct color profile"
echo "  • Is already attached to its Docker container"
echo "  • Has full conversation history"
echo ""
echo "If a tab shows 'Press Enter to attach':"
echo "  Just press Enter - it's waiting for you!"