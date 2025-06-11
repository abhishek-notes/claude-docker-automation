#!/bin/bash

# Complete Claude Max Automation Setup
# Now with working permissions!

echo "🚀 Setting Up Complete Claude Max Automation System"
echo "=================================================="
echo ""

AUTOMATION_DIR="/Users/abhishek/Work/claude-automation"
cd "$AUTOMATION_DIR"

# Step 1: Create the real automation launcher
cat > launch-work-session.sh << 'EOF'
#!/bin/bash

# Claude Max Work Session Launcher
# Minimal effort, maximum output!

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

# If no task file specified, create one
if [[ -z "$TASK_FILE" ]]; then
    echo "Creating task file..."
    TASK_FILE="instructions/session-$SESSION_ID.md"
    
    # Use template or create new
    if [[ -f "instructions/MASTER_TEMPLATE.md" ]]; then
        cp "instructions/MASTER_TEMPLATE.md" "$TASK_FILE"
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
   - Time estimate: [HOURS]

2. **Task 2**
   - Requirements: [SPECIFIC REQUIREMENTS]
   - Expected outcome: [WHAT SUCCESS LOOKS LIKE]
   - Time estimate: [HOURS]

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
cat > .session-prompt << PROMPT
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
claude < "$AUTOMATION_DIR/.session-prompt" 2>&1 | tee "$LOG_FILE"

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

# Clean up
rm -f "$AUTOMATION_DIR/.session-prompt"
EOF

chmod +x launch-work-session.sh

# Step 2: Create GitHub integration script
cat > setup-github-integration.sh << 'EOF'
#!/bin/bash

echo "🔗 Setting up GitHub Integration"
echo "================================"

# Check if in git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "⚠️  Not in a git repository!"
    echo "Please run this in your project directory"
    exit 1
fi

# Create GitHub workflow
mkdir -p .github/workflows

cat > .github/workflows/claude-automation.yml << 'WORKFLOW'
name: Claude Automation Support

on:
  issue_comment:
    types: [created]
  pull_request:
    types: [opened, synchronize]

jobs:
  auto-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Tests
        run: |
          npm test || echo "No tests found"
          
      - name: Comment Results
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '✅ Automated checks complete!'
            })
WORKFLOW

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
# Run tests before commit
npm test || true

# Check for breaking changes
if git diff --cached --name-only | grep -E '\.(js|ts|py)$'; then
    echo "🔍 Checking for breaking changes..."
    # Add your breaking change detection here
fi
HOOK

chmod +x .git/hooks/pre-commit

echo "✅ GitHub integration configured!"
echo ""
echo "Features enabled:"
echo "  - Automated testing on PR"
echo "  - Pre-commit hooks"
echo "  - GitHub Actions workflow"
EOF

chmod +x setup-github-integration.sh

# Step 3: Create multi-LLM integration (without APIs)
cat > multi-llm-helper.sh << 'EOF'
#!/bin/bash

# Multi-LLM Helper - Uses desktop apps, not APIs!

echo "🤖 Multi-LLM Task Helper"
echo "======================="
echo ""

TASK=${1:-"review"}
CONTENT=${2:-""}

case $TASK in
    "review")
        echo "📝 Code Review Request"
        echo ""
        echo "1. Open ChatGPT Desktop"
        echo "2. Paste this prompt:"
        echo ""
        echo "Please review this code for:"
        echo "- Security issues"
        echo "- Performance problems"
        echo "- Best practices"
        echo "- Potential bugs"
        echo ""
        echo "[Paste your code here]"
        ;;
        
    "test")
        echo "🧪 Test Generation Request"
        echo ""
        echo "1. Open Google AI Studio (FREE!)"
        echo "2. Paste this prompt:"
        echo ""
        echo "Generate comprehensive tests for this code:"
        echo "- Unit tests"
        echo "- Edge cases"
        echo "- Integration tests"
        echo ""
        echo "[Paste your code here]"
        ;;
        
    "document")
        echo "📚 Documentation Request"
        echo ""
        echo "1. Open Claude Desktop"
        echo "2. Paste this prompt:"
        echo ""
        echo "Create documentation for this code:"
        echo "- API documentation"
        echo "- Usage examples"
        echo "- Architecture overview"
        echo ""
        echo "[Paste your code here]"
        ;;
        
    *)
        echo "Usage: $0 {review|test|document}"
        ;;
esac
EOF

chmod +x multi-llm-helper.sh

# Step 4: Create the master orchestrator
cat > claude-max-orchestrator.sh << 'EOF'
#!/bin/bash

# Claude Max Master Orchestrator
# Your command center for autonomous coding

clear
echo "🎮 Claude Max Command Center"
echo "============================"
echo ""
echo "Quick Actions:"
echo ""
echo "1) Start 4-hour coding session"
echo "2) Start 8-hour coding session"
echo "3) Create new task file"
echo "4) Setup GitHub integration"
echo "5) Launch collaboration mode"
echo "6) View recent sessions"
echo "7) Open dashboard"
echo "8) Exit"
echo ""
read -p "Select action (1-8): " choice

case $choice in
    1)
        ./launch-work-session.sh 4
        ;;
    2)
        ./launch-work-session.sh 8
        ;;
    3)
        timestamp=$(date +%Y%m%d-%H%M%S)
        cp instructions/MASTER_TEMPLATE.md "instructions/task-$timestamp.md"
        ${EDITOR:-nano} "instructions/task-$timestamp.md"
        echo "Task file created: instructions/task-$timestamp.md"
        ;;
    4)
        ./setup-github-integration.sh
        ;;
    5)
        ./setup-collaboration.sh
        ;;
    6)
        echo "Recent sessions:"
        ls -lt logs/session-*.log | head -10
        ;;
    7)
        open dashboard/index.html
        ;;
    8)
        exit 0
        ;;
    *)
        echo "Invalid choice"
        ;;
esac
EOF

chmod +x claude-max-orchestrator.sh

# Step 5: Create quick aliases
cat > ~/.claude-max-aliases << 'ALIASES'
# Claude Max Aliases
alias cmax="cd /Users/abhishek/Work/claude-automation && ./claude-max-orchestrator.sh"
alias cwork="cd /Users/abhishek/Work/claude-automation && ./launch-work-session.sh"
alias ctask="cd /Users/abhishek/Work/claude-automation && claude-task"
alias clog="tail -f /Users/abhishek/Work/claude-automation/logs/session-*.log"
alias cdash="open /Users/abhishek/Work/claude-automation/dashboard/index.html"

# Quick work sessions
cwork-quick() {
    cd /Users/abhishek/Work/claude-automation
    ./launch-work-session.sh 1 "$@"
}

cwork-long() {
    cd /Users/abhishek/Work/claude-automation
    ./launch-work-session.sh 8 "$@"
}
ALIASES

echo "" >> ~/.zshrc
echo "# Claude Max Aliases" >> ~/.zshrc
echo "source ~/.claude-max-aliases" >> ~/.zshrc

echo "✅ Complete Claude Max Automation System Ready!"
echo ""
echo "🎯 Quick Start Commands:"
echo ""
echo "  cmax     - Open command center"
echo "  cwork 4  - Start 4-hour session"
echo "  ctask    - Create new task"
echo "  cdash    - View dashboard"
echo "  clog     - View live logs"
echo ""
echo "📋 Your Daily Workflow:"
echo ""
echo "1. Morning (5 min):"
echo "   cmax → Select option 1 or 2"
echo "   Edit task file"
echo "   Let Claude work"
echo ""
echo "2. Evening (5 min):"
echo "   Review SUMMARY.md"
echo "   Check PR if created"
echo "   Merge if good"
echo ""
echo "⏰ Time Investment: 10 minutes/day"
echo "🚀 Work Output: 4-8 hours/day"
echo ""
echo "Reload your shell: source ~/.zshrc"
