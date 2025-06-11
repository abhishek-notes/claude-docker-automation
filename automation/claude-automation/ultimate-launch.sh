#!/bin/bash

# Ultimate Claude Automation Launcher
# Usage: ./ultimate-launch.sh [hours] [task-file] [project-dir]

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

# Pre-flight checks
pre_flight_checks() {
    log "Running pre-flight checks..."
    
    # Check Claude Code installation
    if ! command -v claude &> /dev/null; then
        error "Claude Code not found. Install with: npm i -g @anthropic-ai/claude-code"
    fi
    
    # Check Git status
    cd "$PROJECT_DIR"
    if [[ -n $(git status --porcelain) ]]; then
        warning "Uncommitted changes detected. Creating stash..."
        git stash push -m "Auto-stash before Claude session $SESSION_ID"
    fi
    
    # Check for required files
    if [[ ! -f "$TASK_FILE" ]]; then
        warning "Task file not found. Creating from template..."
        cp "$AUTOMATION_DIR/instructions/MASTER_TEMPLATE.md" "$TASK_FILE"
        error "Please edit $TASK_FILE with your tasks before running"
    fi
    
    # Create snapshot
    log "Creating project snapshot..."
    node "$AUTOMATION_DIR/mcp-smart-ops.js" <<< '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "create_snapshot",
            "arguments": {
                "projectPath": "'$PROJECT_DIR'",
                "message": "pre-session-'$SESSION_ID'"
            }
        }
    }' &> /dev/null || warning "Snapshot creation failed"
    
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
    
    # Start monitoring in background
    if command -v tmux &> /dev/null; then
        tmux new-session -d -s "claude-monitor-$SESSION_ID" \
            "watch -n 30 'tail -20 $LOG_FILE'"
        log "Started monitoring in tmux session: claude-monitor-$SESSION_ID"
    fi
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
2. Create a new feature branch: auto/claude/$SESSION_ID
3. Work through each task systematically

## Mandatory Rules

- Use 'versioned_backup' MCP tool before modifying ANY file
- Use 'detect_api_changes' before committing function/API changes  
- Use 'safe_delete' instead of rm for file deletion
- Run full test suite after EACH task completion
- Commit with conventional commit messages
- Push to remote every 30 minutes
- If ANY test fails, fix before proceeding
- If breaking changes detected, STOP and document

## Progress Tracking

- Log progress to: $LOG_FILE every 15 minutes
- Update PROGRESS.md with completed tasks
- Create PR when all tasks complete

## External Tools

- Use /ask-llm command for code reviews
- Document all LLM interactions
- Save important responses to reports/

## Session End

- Generate comprehensive summary
- List all completed tasks
- Document any blockers
- Create pull request with full description
- Run final test suite

Begin autonomous work now.
EOF
}

# Launch Claude
launch_claude() {
    log "Launching Claude Code for $HOURS hour session..."
    
    cd "$PROJECT_DIR"
    
    # Use script to capture all output with proper TTY
    script -q "$LOG_FILE" claude -p "$(cat /tmp/claude-session-$SESSION_ID.md)" &
    CLAUDE_PID=$!
    
    log "Claude Code launched with PID: $CLAUDE_PID"
    
    # Monitor for specified hours
    local end_time=$(($(date +%s) + HOURS * 3600))
    
    while [[ $(date +%s) -lt $end_time ]]; do
        if ! ps -p $CLAUDE_PID > /dev/null; then
            warning "Claude process ended early"
            break
        fi
        
        # Progress indicator
        local remaining=$(( (end_time - $(date +%s)) / 60 ))
        echo -ne "\r${GREEN}Time remaining:${NC} $remaining minutes    "
        
        sleep 60
    done
    
    echo ""
    log "Session time complete"
}

# Post-session cleanup
post_session() {
    log "Running post-session tasks..."
    
    cd "$PROJECT_DIR"
    
    # Check for breaking changes
    if [[ -f "BREAKING_CHANGES.md" ]]; then
        error "⚠️  BREAKING CHANGES DETECTED - Review BREAKING_CHANGES.md before merging!"
    fi
    
    # Generate session report
    cat > "$AUTOMATION_DIR/reports/session-$SESSION_ID.md" << EOF
# Session Report: $SESSION_ID

## Overview
- Duration: $HOURS hours
- Start: $(head -1 "$LOG_FILE" | cut -d' ' -f2)
- End: $(date)
- Project: $PROJECT_DIR

## Git Activity
$(cd "$PROJECT_DIR" && git log --oneline -20 | head -10)

## Test Results
$(cd "$PROJECT_DIR" && npm test 2>&1 | tail -20 || echo "No test results")

## Files Modified
$(cd "$PROJECT_DIR" && git diff --name-only origin/main...HEAD)

## Next Steps
1. Review the pull request
2. Check test coverage
3. Merge if approved
EOF
    
    # Open report
    if command -v open &> /dev/null; then
        open "$AUTOMATION_DIR/reports/session-$SESSION_ID.md"
    fi
    
    # Kill monitoring if running
    tmux kill-session -t "claude-monitor-$SESSION_ID" 2>/dev/null || true
    
    log "Session complete! Report saved to: reports/session-$SESSION_ID.md"
}

# Main execution
main() {
    echo -e "${GREEN}🚀 Claude Automation Ultimate Launcher${NC}"
    echo "========================================"
    
    pre_flight_checks
    setup_environment
    create_session_prompt
    launch_claude
    post_session
    
    echo -e "${GREEN}✅ All done!${NC}"
}

# Run with error handling
trap 'error "Script failed at line $LINENO"' ERR
main "$@"
