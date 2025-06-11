#!/bin/bash

# Create a new tmux session without the problematic dashboard

SESSION="claude-work"

echo "🚀 Creating new tmux session without dashboard..."

# Kill old session if exists
tmux kill-session -t $SESSION 2>/dev/null || true

# Create new session starting with first Claude window
echo "Creating session with first Claude window..."
tmux new-session -d -s $SESSION -n "setup"

# Attach all Claude containers to windows
containers=$(docker ps --filter "name=claude" --format "{{.Names}}")
window_num=0

for container in $containers; do
    if [ $window_num -eq 0 ]; then
        # Use the first window
        tmux rename-window -t $SESSION:0 "$container"
    else
        # Create new windows
        tmux new-window -t $SESSION -n "$container"
    fi
    
    # Send command to attach to container
    tmux send-keys -t $SESSION:$window_num "echo 'Window for $container. Press Enter to attach:'" Enter
    tmux send-keys -t $SESSION:$window_num "docker exec -it $container /bin/bash" 
    
    ((window_num++))
done

echo "✅ Created session '$SESSION' with $(echo "$containers" | wc -l) windows"
echo ""
echo "Now run:"
echo "  tmux -CC attach -t $SESSION"
echo ""
echo "Or use regular attach:"
echo "  tmux attach -t $SESSION"