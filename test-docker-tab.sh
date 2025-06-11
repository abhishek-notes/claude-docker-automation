#!/bin/bash

# Test Docker tab control
echo "Testing Docker tab control..."

# Set environment variables like the API does
export CLAUDE_USE_TABS='true'
export CLAUDE_ITERM_PROFILE='Work'
export CLAUDE_OPEN_NEW_TAB='true'

echo "Environment variables set:"
echo "CLAUDE_USE_TABS=$CLAUDE_USE_TABS"
echo "CLAUDE_ITERM_PROFILE=$CLAUDE_ITERM_PROFILE"
echo "CLAUDE_OPEN_NEW_TAB=$CLAUDE_OPEN_NEW_TAB"

# Create a simple test task
TEST_DIR="/tmp/test-docker-tab-control"
mkdir -p "$TEST_DIR"

cat > "$TEST_DIR/CLAUDE_TASKS.md" << 'EOF'
# Test Task - Docker Tab Control

## Project Overview
- **Goal**: Test if Docker containers open in new tabs correctly

## Tasks

### 1. Simple Test
- **Description**: Just respond with "Hello World" to test the tab functionality
- **Requirements**: 
  - Respond with "Hello World"
- **Acceptance Criteria**: Response received successfully

## Success Criteria
The task is complete when:
1. Response "Hello World" is received
2. Container opened in correct tab (new vs existing)
EOF

echo "Created test task in $TEST_DIR"
echo "Task content:"
cat "$TEST_DIR/CLAUDE_TASKS.md"

# Test the Docker script
echo ""
echo "Testing Docker script with new tab setting..."
./claude-docker-persistent.sh start "$TEST_DIR" CLAUDE_TASKS.md