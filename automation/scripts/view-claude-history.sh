#!/bin/bash

# Script to view full history of any Claude session

echo "🔍 Claude Session History Viewer"
echo ""

# List all sessions
echo "Available sessions:"
docker ps --filter "name=claude" --format "table {{.Names}}\t{{.Status}}" | nl -v 0
echo ""

read -p "Enter session number (0-11) or container name: " choice

# Map number to container name if needed
if [[ "$choice" =~ ^[0-9]+$ ]]; then
    # Get container by index
    container=$(docker ps --filter "name=claude" --format "{{.Names}}" | sed -n "$((choice+1))p")
else
    container="$choice"
fi

if [ -z "$container" ]; then
    echo "Invalid selection"
    exit 1
fi

echo ""
echo "Viewing history for: $container"
echo "Loading last 10,000 lines..."
echo ""
echo "Commands:"
echo "  q - quit"
echo "  / - search"
echo "  n - next match"
echo "  N - previous match"
echo "  G - go to end"
echo "  g - go to beginning"
echo ""
echo "Press Enter to continue..."
read

# Show logs with less
docker logs --tail 10000 "$container" 2>&1 | less -R +G