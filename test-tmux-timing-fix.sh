#!/bin/bash

# Test tmux timing fix
echo "Testing tmux auto-injection timing fix..."

# Create test directory
TEST_DIR="/tmp/test-tmux-timing"
mkdir -p "$TEST_DIR"

# Create simple test task
cat > "$TEST_DIR/CLAUDE_TASKS.md" << 'EOF'
# Tmux Timing Test

## Project Overview
- **Goal**: Test that auto-injection waits for Claude Code to be ready

## Tasks

### 1. Simple Response
- **Description**: Respond with "Tmux timing test successful - content pasted correctly"
- **Requirements**: Confirm the task content was received by Claude Code, not shell
- **Acceptance Criteria**: Response shows task was processed by Claude, not shell

## Success Criteria
The task is complete when Claude Code receives and processes this task content instead of the shell interpreting it as commands.
EOF

echo "Created test task file: $TEST_DIR/CLAUDE_TASKS.md"
echo ""
echo "Test task content:"
echo "=================="
cat "$TEST_DIR/CLAUDE_TASKS.md"
echo "=================="
echo ""

echo "Launching tmux session with manual paste approach..."
echo "This tests the safer manual paste approach to avoid shell interpretation."
echo ""

# Set environment for tmux mode
export CLAUDE_USE_TABS=true
export CLAUDE_ITERM_PROFILE=Default
export CLAUDE_OPEN_NEW_TAB=true

# Test with auto-paste disabled (default)
echo "Testing with manual paste (recommended)..."
./claude-tmux-launcher.sh "$TEST_DIR" "CLAUDE_TASKS.md"

echo ""
echo "Test launched. The tmux session will:"
echo "1. Start Claude Code normally"
echo "2. Display task content preview"  
echo "3. Load task content into tmux paste buffer"
echo "4. Show instructions for manual pasting"
echo ""
echo "To paste the task when Claude Code is ready:"
echo "1. Wait for Claude Code to show its prompt"
echo "2. Press Ctrl+B, then ] (tmux paste)"
echo "3. Task content will be pasted to Claude Code"
echo ""
echo "This prevents shell interpretation errors by ensuring"
echo "Claude Code is ready before pasting task content."