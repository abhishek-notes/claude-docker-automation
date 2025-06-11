#!/bin/bash

# Simple Claude Work Launcher
# Direct and working!

echo "🚀 Claude Work Session"
echo "===================="
echo ""

# Get task file
if [[ -n "$1" ]]; then
    TASK_FILE="$1"
else
    # List available tasks
    echo "Available task files:"
    ls -1 instructions/*.md | nl
    echo ""
    read -p "Select task number (or press Enter to create new): " choice
    
    if [[ -z "$choice" ]]; then
        # Create new task
        TASK_FILE="instructions/task-$(date +%Y%m%d-%H%M%S).md"
        cp instructions/MASTER_TEMPLATE.md "$TASK_FILE" 2>/dev/null || \
        cat > "$TASK_FILE" << 'EOF'
# Today's Tasks

## Task 1
- Description: [What needs to be done]
- Requirements: [Specific requirements]
- Expected outcome: [What success looks like]

## Task 2
- Description: [What needs to be done]
- Requirements: [Specific requirements]
- Expected outcome: [What success looks like]

## Deliverables
- PROGRESS.md with updates
- SUMMARY.md with results
- Any code/documentation created
EOF
        
        echo "Opening editor..."
        ${EDITOR:-nano} "$TASK_FILE"
    else
        # Use selected file
        TASK_FILE=$(ls -1 instructions/*.md | sed -n "${choice}p")
    fi
fi

echo ""
echo "📋 Task file: $TASK_FILE"
echo ""
echo "Starting Claude..."
echo ""

# Create prompt
cat > .claude-prompt << EOF
Please read and complete all tasks in $TASK_FILE

Additional instructions:
1. Create PROGRESS.md and update it as you work
2. Create SUMMARY.md when complete
3. Document any issues in ISSUES.md
4. Exit when all tasks are done

Begin work now.
EOF

# Run Claude
cd /Users/abhishek/Work/claude-automation
claude < .claude-prompt

# Cleanup
rm -f .claude-prompt

echo ""
echo "✅ Session complete!"
echo ""
echo "Results:"
ls -la | grep -E "(PROGRESS|SUMMARY|ISSUES)\.md"
