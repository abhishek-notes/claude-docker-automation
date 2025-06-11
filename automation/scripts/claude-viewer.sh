#!/bin/bash

# Claude Session Viewer - See all your Claude sessions with history

echo "🔍 Claude Session Viewer"
echo ""

# List all containers
containers=$(docker ps --filter "name=claude" --format "{{.Names}}")
count=0

echo "Available sessions:"
for container in $containers; do
  echo "  $count) $container"
  ((count++))
done

echo ""
echo "Commands:"
echo "  a) View all sessions in tabs (with history)"
echo "  0-10) View specific session"
echo "  q) Quit"
echo ""
read -p "Choice: " choice

case $choice in
  a|A)
    # Open all in tabs
    for container in $containers; do
      osascript <<EOF
tell application "iTerm"
  tell current window
    create tab with default profile
    tell current session
      set name to "$container"
      write text "echo '📦 Container: $container'; echo ''; docker logs --tail 10000 $container | less +G"
    end tell
  end tell
end tell
EOF
      sleep 0.5
    done
    echo "✅ Opened all sessions in tabs!"
    ;;
    
  [0-9]|10)
    # View specific session
    container=$(echo "$containers" | sed -n "$((choice+1))p")
    if [ -n "$container" ]; then
      echo "Viewing: $container"
      docker logs --tail 10000 "$container" | less +G
    else
      echo "Invalid selection"
    fi
    ;;
    
  q|Q)
    exit 0
    ;;
    
  *)
    echo "Invalid choice"
    ;;
esac