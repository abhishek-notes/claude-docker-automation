#!/bin/bash

# Test ChatGPT's fix - Claude as primary process in tmux
echo "Testing ChatGPT's tmux fix - Claude as primary process..."

# Create test directory
TEST_DIR="/tmp/test-chatgpt-fix"
mkdir -p "$TEST_DIR"

# Create simple test task
cat > "$TEST_DIR/CLAUDE_TASKS.md" << 'EOF'
# ChatGPT Fix Test

## Project Overview
- **Goal**: Test that Claude runs as primary process (no shell interference)

## Tasks

### 1. Simple Response Test
- **Description**: Respond with "ChatGPT fix successful - no shell interference!"
- **Requirements**: Confirm task content goes to Claude, not shell
- **Acceptance Criteria**: No "zsh: command not found" errors

## Success Criteria
Task is complete when Claude Code processes this content directly without shell interpretation errors.
EOF

echo "Created test task file: $TEST_DIR/CLAUDE_TASKS.md"
echo ""
echo "Key improvements being tested:"
echo "1. Claude Code runs as PRIMARY process (not subprocess of shell)"
echo "2. Instructions display in separate info window"
echo "3. No shell interference during startup"
echo "4. Manual paste goes directly to Claude"
echo ""

# Set environment for tmux mode
export CLAUDE_USE_TABS=true
export CLAUDE_ITERM_PROFILE=Default
export CLAUDE_OPEN_NEW_TAB=true

echo "Launching tmux session with ChatGPT's fix..."
./claude-tmux-launcher.sh "$TEST_DIR" "CLAUDE_TASKS.md"

echo ""
echo "Expected behavior:"
echo "✅ iTerm opens with Claude window (window 0)"
echo "✅ Claude Code starts immediately as primary process"
echo "✅ Info window (window 1) shows instructions"
echo "✅ No 'zsh: command not found' errors"
echo "✅ Task content ready for manual paste: Ctrl+B ]"
echo ""
echo "To verify fix:"
echo "1. Check that Claude prompt appears in window 0"
echo "2. Switch to info window: Ctrl+B 1"
echo "3. Return to Claude: Ctrl+B 0"
echo "4. Paste task: Ctrl+B ]"
echo "5. Verify Claude processes task (no shell errors)"