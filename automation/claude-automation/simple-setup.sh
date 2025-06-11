#!/bin/bash

# Super Simple Claude Automation
# Just approve permissions once and it works!

echo "🎯 SIMPLE Claude Automation Setup"
echo "================================"
echo ""
echo "Here's the EASIEST way to use Claude autonomously:"
echo ""

# Create a simple task file
cat > simple-task.md << 'EOF'
# Simple Test Task

Please do these things:

1. Run `/mcp` to check MCP servers
2. Create a file called RESULTS.md with:
   - Current date and time
   - List of MCP servers
   - A success message
3. Create a directory called `output`
4. Put a file in it: output/timestamp.txt
5. Write "Task completed!" to the console

That's it! Exit when done.
EOF

# Create the simplest possible launcher
cat > simple-launch.sh << 'EOF'
#!/bin/bash
echo "🚀 Launching Claude..."
echo ""
echo "IMPORTANT: When Claude asks for permissions:"
echo "  - Type: y"
echo "  - Press: Enter"
echo "  - Repeat for each permission request"
echo ""
echo "After approving, Claude will work autonomously!"
echo ""
cd /Users/abhishek/Work/claude-automation
claude
EOF

chmod +x simple-launch.sh

echo "✅ Setup complete!"
echo ""
echo "📋 STEP-BY-STEP INSTRUCTIONS:"
echo ""
echo "1. Run this command:"
echo "   ./simple-launch.sh"
echo ""
echo "2. When Claude starts, copy and paste this:"
echo "   Please read and complete the tasks in simple-task.md"
echo ""
echo "3. When Claude asks 'Grant permission?':"
echo "   Type: y"
echo "   Press: Enter"
echo ""
echo "4. Claude will then complete all tasks!"
echo ""
echo "That's it! No complex automation needed."
echo "Just approve permissions once per session."
