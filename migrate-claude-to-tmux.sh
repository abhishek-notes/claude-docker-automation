#!/usr/bin/env bash

# Migrate existing Docker Claude sessions to tmux
# This helps you organize your already-running containers

TMUX_SESSION="claude-main"

echo "=== Migrating Existing Claude Sessions to tmux ==="

# Create tmux session if it doesn't exist
tmux has-session -t "$TMUX_SESSION" 2>/dev/null || \
    tmux new-session -d -s "$TMUX_SESSION" -n "dashboard"

# Get all running Claude containers
docker ps --filter "name=claude-session" --format "{{.Names}}" | while read container; do
    # Extract meaningful name from container
    TASK_NAME=$(echo "$container" | sed -E 's/claude-session-//; s/-[0-9]{8}-[0-9]{6}$//')
    WINDOW_NAME="${TASK_NAME}-existing"
    
    echo "Attaching $container as window: $WINDOW_NAME"
    
    # Create a new tmux window that attaches to the existing container
    tmux new-window -t "$TMUX_SESSION" -n "$WINDOW_NAME" \
        "echo 'Attaching to existing container: $container'; \
         echo 'Use Ctrl-p Ctrl-q to detach safely'; \
         echo ''; \
         docker attach $container; \
         echo ''; \
         echo 'Container detached. Press any key to close...'; \
         read -n 1"
done

echo ""
echo "Migration complete! Your sessions are now in tmux."
echo ""
echo "To access them:"
echo "  tmux attach -t $TMUX_SESSION"
echo ""
echo "Then use:"
echo "  Ctrl-b w     - List and switch between windows"
echo "  Ctrl-b d     - Detach from tmux (leaves everything running)"