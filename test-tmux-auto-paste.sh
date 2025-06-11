#!/bin/bash

# Test tmux auto-paste mode with long delay
echo "Testing tmux auto-paste mode with 2-minute delay..."

# Create test directory
TEST_DIR="/tmp/test-tmux-auto-paste"
mkdir -p "$TEST_DIR"

# Create simple test task
cat > "$TEST_DIR/CLAUDE_TASKS.md" << 'EOF'
# Tmux Auto-Paste Test

## Project Overview
- **Goal**: Test auto-paste with 2-minute delay

## Tasks

### 1. Simple Response
- **Description**: Respond with "Auto-paste successful - 2 minute delay worked"
- **Requirements**: Confirm task was auto-pasted after sufficient delay
- **Acceptance Criteria**: Claude Code processes task, not shell

## Success Criteria
Task is complete when Claude Code receives and processes this content after 2-minute auto-paste delay.
EOF

echo "Created test task file: $TEST_DIR/CLAUDE_TASKS.md"
echo ""

# Set environment for tmux mode with auto-paste enabled
export CLAUDE_USE_TABS=true
export CLAUDE_ITERM_PROFILE=Default
export CLAUDE_OPEN_NEW_TAB=true
export CLAUDE_AUTO_PASTE=true

echo "Testing with auto-paste enabled (2-minute delay)..."
./claude-tmux-launcher.sh "$TEST_DIR" "CLAUDE_TASKS.md"

echo ""
echo "Auto-paste test launched. The session will:"
echo "1. Start Claude Code"
echo "2. Wait exactly 2 minutes"
echo "3. Automatically paste task content"
echo "4. Send Enter to submit"
echo ""
echo "This tests whether a 2-minute delay is sufficient"
echo "for Claude Code to be ready to receive task content."
echo ""
echo "Watch the tmux session for 2 minutes to see if auto-paste works."