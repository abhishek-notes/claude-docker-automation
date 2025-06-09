#!/bin/bash

# Test script for the fixed launcher
echo "🧪 Testing Claude launcher fix..."

# Create a test directory
TEST_DIR="/tmp/claude-test-$(date +%s)"
mkdir -p "$TEST_DIR"

# Create a simple test task
cat > "$TEST_DIR/CLAUDE_TASKS.md" << 'EOF'
# Test Task

## Task 1: Simple Test
- Create a file named test.txt
- Write "Hello from Claude" in it
- Create PROGRESS.md
- Create SUMMARY.md
EOF

echo "📁 Test directory: $TEST_DIR"
echo "📋 Test task created"
echo ""
echo "🚀 Launching Claude with test task..."
echo ""

# Run the fixed launcher
./claude-launcher-fixed.sh "$TEST_DIR" "CLAUDE_TASKS.md" "test-session"

echo ""
echo "✅ Test completed"
echo ""
echo "📊 Checking results:"
ls -la "$TEST_DIR"

# Clean up
echo ""
read -p "Press Enter to clean up test directory..."
rm -rf "$TEST_DIR"