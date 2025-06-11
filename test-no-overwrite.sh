#!/bin/bash

# Test that original CLAUDE_TASKS.md is not overwritten
echo "Testing tmux launcher - ensuring original task file is preserved..."

# Create test directory
TEST_DIR="/tmp/test-no-overwrite"
mkdir -p "$TEST_DIR"

# Create original test task
ORIGINAL_CONTENT="# Original Task File

## Simple Test
- Just respond: Hello from original task file

This file should NOT be overwritten."

echo "$ORIGINAL_CONTENT" > "$TEST_DIR/CLAUDE_TASKS.md"

echo "Original task file content:"
echo "=========================="
cat "$TEST_DIR/CLAUDE_TASKS.md"
echo "=========================="
echo ""

echo "Launching tmux with preserved original file..."
export CLAUDE_USE_TABS=true
export CLAUDE_ITERM_PROFILE=Default
export CLAUDE_OPEN_NEW_TAB=true

# Launch the test  
./claude-tmux-launcher.sh "$TEST_DIR" "CLAUDE_TASKS.md" &
LAUNCHER_PID=$!

# Wait a moment for launcher to process
sleep 3

echo ""
echo "Checking if original file was preserved..."
echo "Current task file content:"
echo "=========================="
cat "$TEST_DIR/CLAUDE_TASKS.md"
echo "=========================="

# Compare with original
if diff <(echo "$ORIGINAL_CONTENT") "$TEST_DIR/CLAUDE_TASKS.md" > /dev/null; then
    echo "✅ SUCCESS: Original task file was preserved!"
    echo "✅ No auto-injection via file overwrite"
else
    echo "❌ FAILED: Original task file was modified"
    echo "❌ This causes auto-injection issues"
fi

# Clean up
kill $LAUNCHER_PID 2>/dev/null || true
rm -rf "$TEST_DIR"

echo ""
echo "This test verifies that Claude Code won't auto-inject"
echo "because the original CLAUDE_TASKS.md remains unchanged."