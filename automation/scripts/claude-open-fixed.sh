#!/usr/bin/env bash
# Fixed version - automatically enters containers after creating sessions

BASE=claude-main

profile_for() {
  case "$1" in
    palladio*)   echo "Palladio" ;;
    work*)       echo "Work"     ;;
    automation*) echo "Automation" ;;
    *)           echo "Default"  ;;
  esac
}

echo "🚀 Opening Claude sessions with auto-attach..."

# Clean up any existing clone sessions first
for i in {1..11}; do
  tmux kill-session -t "${BASE}-${i}" 2>/dev/null || true
done

# Get container names for each window
declare -A window_containers
window_num=1
for container in $(docker ps --filter "name=claude" --format "{{.Names}}"); do
  window_containers[$window_num]=$container
  ((window_num++))
done

# Now create sessions and auto-attach
tmux list-windows -t "$BASE" -F "#{window_index} #{window_name}" |
while read -r idx name; do
  [ "$idx" = "0" ] && continue    # skip dashboard
  
  newsess="${BASE}-${idx}"
  container="${window_containers[$idx]}"
  
  echo "  Window $idx: $name → Container: $container"
  
  # Create session
  tmux new-session -d -s "$newsess" -t "$BASE:$idx"
  
  # Immediately send the docker exec command
  tmux send-keys -t "$newsess" C-m  # Press Enter to execute waiting command
  
  # Open iTerm tab
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
  
  sleep 0.5
done

echo "✅ All windows opened and attached to containers!"
echo ""
echo "Each tab now shows:"
echo "  • The Docker container shell"
echo "  • Full tmux scrollback history"
echo "  • Ready to interact with Claude's workspace"