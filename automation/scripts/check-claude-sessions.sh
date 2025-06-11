#!/bin/bash

# Reconnect to existing Claude Code sessions in containers

SESSION="claude-main"

echo "🔄 Reconnecting to existing Claude Code sessions..."

# First, check what's in our current tmux windows
echo "Current tmux windows:"
tmux list-windows -t $SESSION -F "#I: #W (#{pane_tty})"
echo ""

# For each container, we need to find and attach to the Claude Code tty
containers=$(docker ps --filter "name=claude" --format "{{.Names}}")

for container in $containers; do
  echo "Checking $container..."
  
  # Find the Claude Code process
  claude_tty=$(docker exec $container sh -c "ps aux | grep 'node.*claude' | grep -v grep | awk '{print \$7}' | head -1")
  
  if [ -n "$claude_tty" ] && [ "$claude_tty" != "?" ]; then
    echo "  Found Claude Code on $claude_tty"
    
    # We can't directly attach to an existing tty in Docker
    # But we can see the logs!
    echo "  Getting last 1000 lines of history..."
    docker logs --tail 1000 $container 2>&1 | tail -100 > /tmp/${container}_history.txt
    echo "  Saved to /tmp/${container}_history.txt"
  else
    echo "  No active Claude Code session found"
  fi
done

echo ""
echo "⚠️  The issue: Claude Code is running but tmux can't reattach to the existing TTY"
echo ""
echo "Options:"
echo "1. View the Docker logs for each container:"
echo "   docker logs --tail 10000 <container-name> | less"
echo ""
echo "2. Start fresh Claude Code sessions (will lose current state)"
echo ""
echo "3. Use the existing bash shells to explore the workspace"