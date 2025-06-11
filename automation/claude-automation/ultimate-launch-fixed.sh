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
        mkdir -p "$(dirname "$TASK_FILE")"
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
