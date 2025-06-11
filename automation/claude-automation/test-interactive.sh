#!/bin/bash

# Simple Claude Interactive Test
echo "🧪 Claude Code Interactive Test"
echo "=============================="
echo ""

cd /Users/abhishek/Work/claude-automation

# Create a simple test instruction
cat > test-instruction.md << 'EOF'
# Quick Test Tasks (5 minutes)

Please complete these tasks to verify the setup:

1. **Check MCP Servers**
   - Run `/mcp` command
   - List all available servers

2. **Create Test Files**
   - Create a file: SETUP_TEST.md
   - Add the current date and time
   - List the MCP servers you found
   - Note if filesystem MCP is working

3. **Test File Operations**
   - Create a directory: test-results
   - Create a file in it: test-results/timestamp.txt
   - Add the current timestamp

4. **Create Summary**
   - Create TEST_COMPLETE.md
   - Summarize what worked and what didn't

Complete these tasks and then exit.
EOF

echo "📋 Test instruction created"
echo ""
echo "Launching Claude Code in a new terminal..."
echo "Claude will complete the test tasks and exit."
echo ""

# Create test launcher
cat > run-test.sh << 'EOF'
#!/bin/bash
cd /Users/abhishek/Work/claude-automation
echo "🚀 Starting Claude Code Test"
echo "=========================="
echo ""
echo "Claude will now complete test tasks..."
echo ""

claude

echo ""
echo "✅ Test session complete!"
echo ""
echo "Check these files:"
echo "- SETUP_TEST.md"
echo "- TEST_COMPLETE.md"
echo "- test-results/"
echo ""
read -p "Press Enter to close this window..."
EOF

chmod +x run-test.sh

# Launch in terminal
osascript << 'EOF'
tell application "Terminal"
    activate
    do script "cd /Users/abhishek/Work/claude-automation && ./run-test.sh"
end tell
EOF

echo "✅ Claude launched in new Terminal window"
echo ""
echo "After Claude completes the test, check for:"
echo "  - SETUP_TEST.md"
echo "  - TEST_COMPLETE.md"
echo "  - test-results/ directory"
echo ""
echo "This will verify your MCP servers and permissions are working!"
