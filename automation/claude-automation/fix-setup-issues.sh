#!/bin/bash

# Fix Claude Automation Setup Issues

echo "🔧 Fixing Claude Automation Setup..."

# 1. Source the aliases that were created
echo "" >> ~/.zshrc
echo "# Claude Automation Aliases" >> ~/.zshrc
echo "source /Users/abhishek/Work/claude-automation/setup-aliases.sh" >> ~/.zshrc

# 2. Fix the Claude alias (remove non-existent flags)
cat > ~/.claude-code-aliases << 'EOF'
# Claude Code Aliases (Fixed)

# Main alias - Claude Code doesn't have those flags
alias claude='claude'

# Task management
alias claude-work="/Users/abhishek/Work/claude-automation/ultimate-launch.sh"
alias claude-dash="open /Users/abhishek/Work/claude-automation/dashboard/index.html"
alias claude-logs="cd /Users/abhishek/Work/claude-automation/logs && ls -la"
alias claude-backup="cd /Users/abhishek/Work/claude-automation/backups && ls -la"
alias claude-collab="/Users/abhishek/Work/claude-automation/collaboration/orchestrate.sh"
alias claude-status="ps aux | grep -E '(claude|node.*mcp)' | grep -v grep"

# Quick task creation function
claude-task() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local filename="/Users/abhishek/Work/claude-automation/instructions/task-$timestamp.md"
    cp /Users/abhishek/Work/claude-automation/instructions/MASTER_TEMPLATE.md "$filename"
    echo "Created new task file: $filename"
    ${EDITOR:-nano} "$filename"
}

# Session management
claude-session() {
    case "$1" in
        start)
            /Users/abhishek/Work/claude-automation/ultimate-launch.sh "${2:-4}" "${3:-}"
            ;;
        stop)
            pkill -f "claude" || true
            echo "Claude sessions stopped"
            ;;
        status)
            claude-status
            ;;
        *)
            echo "Usage: claude-session {start|stop|status} [hours] [task-file]"
            ;;
    esac
}
EOF

# 3. Fix the ultimate-launch.sh to handle non-git directories
cat > /Users/abhishek/Work/claude-automation/ultimate-launch-fixed.sh << 'EOF'
#!/bin/bash

# Fixed Ultimate Claude Automation Launcher
# Works without git repository

set -euo pipefail

# Configuration
HOURS=${1:-4}
TASK_FILE=${2:-"instructions/today.md"}
PROJECT_DIR=${3:-$(pwd)}
AUTOMATION_DIR="/Users/abhishek/Work/claude-automation"
LOG_DIR="$AUTOMATION_DIR/logs"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SESSION_ID="session-$TIMESTAMP"
LOG_FILE="$LOG_DIR/$SESSION_ID.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Pre-flight checks (Git-optional version)
pre_flight_checks() {
    log "Running pre-flight checks..."
    
    # Check Claude Code installation
    if ! command -v claude &> /dev/null; then
        error "Claude Code not found. Install with: npm i -g @anthropic-ai/claude-code"
    fi
    
    # Check Git status (optional)
    cd "$PROJECT_DIR"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        if [[ -n $(git status --porcelain 2>/dev/null || true) ]]; then
            warning "Uncommitted changes detected. Creating stash..."
            git stash push -m "Auto-stash before Claude session $SESSION_ID"
        fi
    else
        warning "Not a git repository. Skipping git operations..."
    fi
    
    # Check for required files
    if [[ ! -f "$TASK_FILE" ]]; then
        warning "Task file not found. Creating from template..."
        cp "$AUTOMATION_DIR/instructions/MASTER_TEMPLATE.md" "$TASK_FILE"
        echo ""
        echo "📝 Created task file: $TASK_FILE"
        echo "Please edit it with your tasks and run again!"
        ${EDITOR:-nano} "$TASK_FILE"
        exit 0
    fi
    
    log "Pre-flight checks complete ✓"
}

# Setup environment
setup_environment() {
    log "Setting up environment..."
    
    # Export API keys if available
    if [[ -f "$AUTOMATION_DIR/.env" ]]; then
        export $(cat "$AUTOMATION_DIR/.env" | xargs)
    fi
    
    # Ensure directories exist
    mkdir -p "$LOG_DIR"
    mkdir -p "$AUTOMATION_DIR/backups"
    mkdir -p "$AUTOMATION_DIR/reports"
}

# Create session prompt
create_session_prompt() {
    cat > "/tmp/claude-session-$SESSION_ID.md" << EOF
# Autonomous Coding Session

**Session ID**: $SESSION_ID
**Duration**: $HOURS hours
**Start Time**: $(date)
**Project**: $PROJECT_DIR

## Instructions

1. Read the task file completely: $TASK_FILE
2. If in a git repo, create a new feature branch: auto/claude/$SESSION_ID
3. Work through each task systematically

## Mandatory Rules

- Use MCP filesystem server for file operations when available
- Run tests after EACH task completion (if tests exist)
- Commit frequently with clear messages (if git repo)
- If ANY test fails, fix before proceeding
- Document all changes

## Progress Tracking

- Log progress every 15 minutes
- Create summary at completion

## Session End

- Generate comprehensive summary
- List all completed tasks
- Document any blockers

Begin autonomous work now.
EOF
}

# Launch Claude
launch_claude() {
    log "Launching Claude Code for $HOURS hour session..."
    
    cd "$PROJECT_DIR"
    
    # Just launch Claude with the prompt file
    log "Starting Claude Code..."
    claude -p "$(cat /tmp/claude-session-$SESSION_ID.md)" 2>&1 | tee -a "$LOG_FILE" &
    CLAUDE_PID=$!
    
    log "Claude Code launched with PID: $CLAUDE_PID"
    log "Session will run for $HOURS hours"
    log ""
    log "You can:"
    log "  - Monitor progress: tail -f $LOG_FILE"
    log "  - Stop early: kill $CLAUDE_PID"
    log ""
    
    # Wait for completion or timeout
    local end_time=$(($(date +%s) + HOURS * 3600))
    
    while [[ $(date +%s) -lt $end_time ]]; do
        if ! ps -p $CLAUDE_PID > /dev/null 2>&1; then
            warning "Claude process ended"
            break
        fi
        sleep 60
    done
    
    log "Session complete"
}

# Post-session
post_session() {
    log "Session complete!"
    log "Review log at: $LOG_FILE"
    
    # Simple summary
    echo ""
    echo "📊 Session Summary"
    echo "=================="
    echo "Duration: $HOURS hours"
    echo "Log file: $LOG_FILE"
    echo "Project: $PROJECT_DIR"
}

# Main execution
main() {
    echo -e "${GREEN}🚀 Claude Automation Launcher${NC}"
    echo "=============================="
    
    pre_flight_checks
    setup_environment
    create_session_prompt
    launch_claude
    post_session
}

main "$@"
EOF

chmod +x /Users/abhishek/Work/claude-automation/ultimate-launch-fixed.sh

# 4. Create a simple task file for testing
cat > /Users/abhishek/Work/claude-automation/instructions/today.md << 'EOF'
# Today's Tasks

## Project Context
- Working in: Claude Automation System
- Goal: Test the automation setup

## Tasks

1. Test File Operations
   - Create a test file
   - Read and modify it
   - Document the process

2. Test MCP Servers
   - Check if filesystem MCP is working
   - List available MCP servers
   - Document findings

## Rules
- Log all activities
- Create summary at end
EOF

echo "✅ Fixes applied!"
echo ""
echo "🚀 Now run these commands:"
echo ""
echo "1. Reload your shell:"
echo "   source ~/.zshrc"
echo ""
echo "2. Test the aliases:"
echo "   claude-task    # Create a new task"
echo "   claude-dash    # Open dashboard"
echo ""
echo "3. Launch automation (with the fixed script):"
echo "   /Users/abhishek/Work/claude-automation/ultimate-launch-fixed.sh 1"
echo ""
echo "📝 Notes:"
echo "- Claude Code doesn't have --auto-approve flags"
echo "- The automation works without git (with warnings)"
echo "- Task file opens in editor if it doesn't exist"
