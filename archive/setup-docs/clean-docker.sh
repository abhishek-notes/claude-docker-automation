#!/bin/bash

# Clean Docker Build Script
# Use this if you want to start fresh

echo "🧹 Cleaning up Docker environment..."

# Stop any running containers
docker stop $(docker ps -q --filter name="claude-session") 2>/dev/null || true

# Remove Claude automation containers
docker rm $(docker ps -aq --filter name="claude-session") 2>/dev/null || true

# Remove the image if it exists
docker rmi claude-automation:latest 2>/dev/null || true

# Clean up Docker build cache
docker builder prune -f

echo "✅ Cleanup complete!"
echo ""
echo "Now run: ./setup.sh"
