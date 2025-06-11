#!/bin/bash

# Claude Automation - Working Version
# Now that permissions are fixed, this will work smoothly!

echo "🚀 Claude Automation Launcher (Working Version)"
echo "============================================="
echo ""

# Default values
TASK_FILE=${1:-"instructions/today.md"}

# Check if task file exists
if [[ ! -f "$TASK_FILE" ]]; then
    echo "❌ Task file not found: $TASK_FILE"
    echo ""
    echo "Available task files:"
    ls -1 instructions/*.md 2>/dev/null || echo "No task files found"
    echo ""
    echo "Usage: $0 [task-file]"
    echo "Example: $0 instructions/test-automation.md"
    exit 1
fi

echo "📋 Task file: $TASK_FILE"
echo ""
echo "Starting Claude Code..."
echo "Claude will read and execute the tasks autonomously."
echo ""

# Create a prompt file that tells Claude what to do
cat > .claude-prompt << EOF
Please read and complete all tasks in $TASK_FILE

Additional instructions:
1. Create PROGRESS.md and update it as you work
2. Create SUMMARY.md when you're done
3. Log any issues in ISSUES.md
4. Exit when all tasks are complete
EOF

# Launch Claude with the prompt
cd /Users/abhishek/Work/claude-automation
claude < .claude-prompt

echo ""
echo "✅ Claude session complete!"
echo ""
echo "Check these files for results:"
[[ -f "PROGRESS.md" ]] && echo "  ✓ PROGRESS.md"
[[ -f "SUMMARY.md" ]] && echo "  ✓ SUMMARY.md"
[[ -f "ISSUES.md" ]] && echo "  ✓ ISSUES.md"
[[ -f "RESULTS.md" ]] && echo "  ✓ RESULTS.md"
echo ""

# Clean up
rm -f .claude-prompt
