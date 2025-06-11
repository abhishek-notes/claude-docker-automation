#!/bin/bash

# Test Docker API launch with tab control
echo "Testing Docker container launch via API..."

# Start the API server in background if not running
if ! pgrep -f "task-api.js" > /dev/null; then
    echo "Starting API server..."
    node task-api.js &
    API_PID=$!
    sleep 3
    echo "API server started with PID: $API_PID"
else
    echo "API server already running"
    API_PID=""
fi

# Create test directory and task
TEST_DIR="/tmp/test-docker-tab-api"
mkdir -p "$TEST_DIR"

cat > "$TEST_DIR/CLAUDE_TASKS.md" << 'EOF'
# Docker Tab Control Test

## Project Overview
- **Goal**: Test Docker tab control via API

## Tasks

### 1. Simple Response
- **Description**: Just respond with "Docker tab test successful"
- **Requirements**: Respond with exact text
- **Acceptance Criteria**: Response received in correct tab

## Success Criteria
The task is complete when response is received in new/existing tab as configured.
EOF

# Test with new tab (default)
echo ""
echo "Testing Docker with NEW TAB (openInNewTab: true)..."

curl -X POST http://localhost:3456/api/launch-task \
  -H "Content-Type: application/json" \
  -d "{
    \"projectPath\": \"$TEST_DIR\",
    \"taskContent\": \"$(cat "$TEST_DIR/CLAUDE_TASKS.md" | sed 's/"/\\"/g' | tr '\n' ' ')\",
    \"sessionId\": \"test-docker-new-tab-$(date +%s)\",
    \"itermProfile\": \"Work\",
    \"useDocker\": true,
    \"openInNewTab\": true
  }"

echo ""
echo "Waiting 5 seconds for container launch..."
sleep 5

# Check logs for Docker debug messages
echo ""
echo "Recent Docker debug logs:"
tail -n 20 logs/safety-system.log | grep -E "(Docker mode detected|Attempting to open|iTerm.*tab.*successfully|iTerm.*tab.*failed)"

# Cleanup
if [ -n "$API_PID" ]; then
    echo ""
    echo "Stopping API server..."
    kill $API_PID 2>/dev/null || true
fi

echo ""
echo "Test completed. Check iTerm for new Docker container tab."
echo "Container should be visible with: docker ps | grep $(date +%Y%m%d)"