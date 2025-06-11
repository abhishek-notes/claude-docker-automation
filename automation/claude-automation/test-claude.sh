#!/bin/bash

# Simple Claude Test Script
echo "🧪 Testing Claude Code Setup"
echo "=========================="

# Test 1: Check Claude installation
echo -n "✓ Claude Code installed: "
if command -v claude &> /dev/null; then
    echo "YES"
else
    echo "NO - Install with: npm i -g @anthropic-ai/claude-code"
    exit 1
fi

# Test 2: Check MCP servers
echo -n "✓ Checking MCP servers: "
cd /Users/abhishek/Work/claude-automation
echo "Running claude with MCP check..."

# Create a test prompt
cat > /tmp/claude-test-prompt.txt << 'EOF'
Please check and list MCP servers by running:
/mcp

Then create a test file called TEST_RESULT.md with:
1. List of MCP servers found
2. Whether filesystem MCP is working
3. Current date and time

Exit after creating the file.
EOF

# Run Claude with timeout
echo ""
echo "Launching Claude for quick test..."
timeout 60s claude < /tmp/claude-test-prompt.txt || true

# Check if test file was created
if [[ -f "TEST_RESULT.md" ]]; then
    echo ""
    echo "✅ Test completed! Results:"
    cat TEST_RESULT.md
else
    echo ""
    echo "⚠️  Test file not created. Claude may need manual interaction."
fi

echo ""
echo "📝 To run a full session, use:"
echo "   ./claude-launcher.sh 1 instructions/test-automation.md"
