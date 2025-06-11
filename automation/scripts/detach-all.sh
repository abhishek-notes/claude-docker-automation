#!/bin/bash

echo "Detaching all clients from tmux..."

# Get all clients and detach them
tmux list-clients | cut -d: -f1 | while read client; do
    echo "Detaching client: $client"
    tmux detach-client -t "$client"
done

echo "✅ All clients detached"
echo ""
echo "Now close all your iTerm tabs and run 'ca' again"