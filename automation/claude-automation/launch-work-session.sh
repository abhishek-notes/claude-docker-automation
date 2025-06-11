#!/bin/bash

# Claude Max Work Session Launcher - FIXED
# Minimal effort, maximum output!

# Base directory
AUTOMATION_DIR="/Users/abhishek/Work/claude-automation"

# Configuration
HOURS=${1:-4}
TASK_FILE=${2:-""}
PROJECT_DIR=${3:-$(pwd)}
SESSION_ID="session-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$AUTOMATION_DIR/logs/$SESSION_ID.log"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🤖 Claude Max Autonomous Work Session${NC}"
echo "====================================="
echo ""

# Ensure directories exist
mkdir -p "$AUTOMATION_DIR/logs"
mkdir -p "$AUTOMATION_DIR/instructions"

# If no task file specified, create one
if [[ -z "$TASK_FILE" ]]; then
    echo "Creating task file..."
    TASK_FILE="$AUTOMATION_DIR/instructions/$SESSION_ID.md"
    
    # Use template or create new
    if [[ -f "$AUTOMATION_DIR/instructions/MASTER_TEMPLATE.md" ]]; then
        cp "$AUTOMATION_DIR/instructions/MASTER_TEMPLATE.md" "$TASK_FILE"
    else
        cat > "$TASK_FILE" << 'TEMPLATE'
# Work Session Tasks

## Project Context
- Repository: [YOUR PROJECT]
- Goal: [SESSION GOAL]

## Today's Tasks

1. **Task 1**
   - Requirements: [SPECIFIC REQUIREMENTS]
   - Expected outcome: [WHAT SUCCESS LOOKS LIKE]
   - Time estimate: 1 hour

2. **Task 2**
   - Requirements: [SPECIFIC REQUIREMENTS]
   - Expected outcome: [WHAT SUCCESS LOOKS LIKE]
   - Time estimate: 1 hour

## Rules
- Create feature branch for changes
- Write tests for new code
- Document all changes
- Create PR description when done

## Deliverables
- Updated code
- Test files
- Documentation
- SUMMARY.md with all changes
TEMPLATE
    fi
    
    echo -e "${YELLOW}Opening task file for editing...${NC}"
    ${EDITOR:-nano} "$TASK_FILE"
fi

echo -e "${BLUE}📋 Session Configuration:${NC}"
echo "- Duration: $HOURS hours"
echo "- Task File: $TASK_FILE"
echo "- Project: $PROJECT_DIR"
echo "- Session ID: $SESSION_ID"
echo ""

# Create session prompt
cat > "$AUTOMATION_DIR/.session-prompt" << PROMPT
You are starting a $HOURS hour autonomous work session.

Instructions:
1. Read and complete all tasks in $TASK_FILE
2. Create PROGRESS.md and update it every 30 minutes
3. If in a git repository:
   - Create feature branch: feature/$SESSION_ID
   - Commit changes frequently
   - Create PR description at end
4. Document all work in SUMMARY.md
5. Log any issues in ISSUES.md
6. Work autonomously for $HOURS hours
7. Exit when time is up or tasks complete

Begin work now.
PROMPT

# Launch Claude
cd "$PROJECT_DIR"
echo -e "${GREEN}Starting Claude Max...${NC}"
echo ""

# Use the working claude automation script
if [[ -f "$AUTOMATION_DIR/claude-auto.sh" ]]; then
    "$AUTOMATION_DIR/claude-auto.sh" "$TASK_FILE" 2>&1 | tee "$LOG_FILE"
else
    # Fallback to direct claude
    claude < "$AUTOMATION_DIR/.session-prompt" 2>&1 | tee "$LOG_FILE"
fi

# Post-session report
echo ""
echo -e "${GREEN}✅ Session Complete!${NC}"
echo ""
echo "📊 Results:"
[[ -f "PROGRESS.md" ]] && echo "  ✓ Progress tracked"
[[ -f "SUMMARY.md" ]] && echo "  ✓ Summary created"
[[ -f "ISSUES.md" ]] && echo "  ✓ Issues logged"
echo ""
echo "📁 Session artifacts:"
echo "  - Task file: $TASK_FILE"
echo "  - Log file: $LOG_FILE"
echo ""

# Show summary if exists
if [[ -f "SUMMARY.md" ]]; then
    echo "📄 Summary Preview:"
    head -20 SUMMARY.md
fi

# Clean up
rm -f "$AUTOMATION_DIR/.session-prompt"
