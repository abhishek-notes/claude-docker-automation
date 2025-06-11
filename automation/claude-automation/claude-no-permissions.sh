#!/bin/bash

# Claude Max Work Launcher - NO PERMISSIONS VERSION
# Uses --dangerously-skip-permissions flag

echo "🚀 Claude Work Session (No Permissions!)"
echo "======================================="
echo ""

# Get task file
TASK_FILE=${1:-""}

if [[ -z "$TASK_FILE" ]]; then
    # List available tasks
    echo "Available task files:"
    ls -1 instructions/*.md 2>/dev/null | nl
    echo ""
    read -p "Select task number (or 0 for new): " choice
    
    if [[ "$choice" == "0" ]]; then
        # Create new task
        TASK_FILE="instructions/task-$(date +%Y%m%d-%H%M%S).md"
        cat > "$TASK_FILE" << 'EOF'
# Today's Work Tasks

## Task 1: [Title]
- Description: [What needs to be done]
- Requirements: [Specific requirements]
- Expected outcome: [What success looks like]

## Task 2: [Title]
- Description: [What needs to be done]
- Requirements: [Specific requirements]
- Expected outcome: [What success looks like]

## Deliverables
- PROGRESS.md with regular updates
- SUMMARY.md with final results
- Any code/documentation created

## Notes
- Work autonomously
- Commit changes if in git repo
- Document any issues encountered
EOF
        
        echo "Opening editor..."
        ${EDITOR:-nano} "$TASK_FILE"
    else
        # Use selected file
        TASK_FILE=$(ls -1 instructions/*.md 2>/dev/null | sed -n "${choice}p")
    fi
fi

if [[ ! -f "$TASK_FILE" ]]; then
    echo "Error: Task file not found!"
    exit 1
fi

echo "📋 Task file: $TASK_FILE"
echo ""
echo "Starting Claude with NO PERMISSION PROMPTS..."
echo ""

# Create session log
SESSION_ID=$(date +%Y%m%d-%H%M%S)
LOG_FILE="logs/session-$SESSION_ID.log"
mkdir -p logs

# Run Claude with the dangerous flag
cd /Users/abhishek/Work/claude-automation

claude --dangerously-skip-permissions -p "Please read and complete all tasks in $TASK_FILE

Additional instructions:
1. Create PROGRESS.md and update it as you work
2. Create SUMMARY.md when complete
3. Document any issues in ISSUES.md
4. Work autonomously without asking for permissions
5. Exit when all tasks are done" 2>&1 | tee "$LOG_FILE"

echo ""
echo "✅ Session complete!"
echo ""
echo "📊 Results:"
[[ -f "PROGRESS.md" ]] && echo "  ✓ Progress tracked"
[[ -f "SUMMARY.md" ]] && echo "  ✓ Summary created"
[[ -f "ISSUES.md" ]] && echo "  ✓ Issues logged"
echo ""
echo "📁 Log saved to: $LOG_FILE"
