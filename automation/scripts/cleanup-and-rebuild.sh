#!/bin/bash

# Clean up the mess and start fresh

echo "🧹 Cleaning up tmux sessions..."

# Kill all the clone sessions
for i in {1..11}; do
  tmux kill-session -t "claude-main-$i" 2>/dev/null || true
done

# Kill the main session too
tmux kill-session -t claude-main 2>/dev/null || true

echo "✅ All tmux sessions cleaned up"
echo ""
echo "Now let's create a fresh setup..."
echo ""

# Create new session with existing Docker containers already attached
SESSION="claude-main"

echo "Creating new tmux session..."
tmux new-session -d -s $SESSION -n "dashboard"

# Start dashboard in window 0
tmux send-keys -t $SESSION:0 '
while true; do
  clear
  echo -e "\033[1;36m🤖 Claude Docker Sessions\033[0m"
  echo ""
  docker ps --filter name=claude --format "table {{.Names}}\t{{.Status}}" | head -20
  echo ""
  echo "Updated: $(date)"
  echo "Press Ctrl-C to stop"
  sleep 2
done' C-m

# Get all running Claude containers
containers=$(docker ps --filter "name=claude" --format "{{.Names}}")
window_num=1

for container in $containers; do
  echo "Creating window $window_num for: $container"
  
  # Create window
  tmux new-window -t $SESSION -n "${container:0:20}"
  
  # Check what's already running in the container
  if docker exec $container ps aux | grep -q "claude\|node"; then
    echo "  Claude Code already running in $container"
    # Just attach to the container's existing shell
    tmux send-keys -t $SESSION:$window_num "docker exec -it $container /bin/bash" C-m
  else
    echo "  Starting fresh shell in $container"
    tmux send-keys -t $SESSION:$window_num "docker exec -it $container /bin/bash" C-m
  fi
  
  ((window_num++))
done

echo ""
echo "✅ Fresh tmux session created!"
echo ""
echo "Total windows: $window_num (including dashboard)"
echo ""
echo "Now run: ca"