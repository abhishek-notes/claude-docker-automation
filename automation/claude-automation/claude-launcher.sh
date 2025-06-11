#!/bin/bash

# Fixed Ultimate Claude Automation Launcher v2
# Works without git repository and handles decimal hours

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

# Convert hours to minutes (handles decimals)
MINUTES=$(echo "$HOURS * 60" | bc)
MINUTES=${MINUTES%.*}  # Remove decimal part

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
        set -a
        source "$AUTOMATION_DIR/.env"
        set +a
    fi
    
    # Ensure directories exist
    mkdir -p "$LOG_DIR"
    mkdir -p "$AUTOMATION_DIR/backups"
    mkdir -p "$AUTOMATION_DIR/reports"
}

# Create session prompt
create_session_prompt() {
    local TASK_CONTENT=$(cat "$TASK_FILE")
    
    cat > "/tmp/claude-session-$SESSION_ID.txt" << EOF
# Autonomous Coding Session

**Session ID**: $SESSION_ID
**Duration**: $HOURS hours ($MINUTES minutes)
**Start Time**: $(date)
**Project**: $PROJECT_DIR

## Task File Content:

$TASK_CONTENT

## Additional Instructions:

1. Work through each task systematically
2. Use MCP servers if available (check with /mcp)
3. Log progress frequently
4. Create SUMMARY.md at the end with:
   - Tasks completed
   - Any issues encountered
   - Files created/modified

Begin autonomous work now.
EOF
}

# Launch Claude
launch_claude() {
    log "Launching Claude Code for $HOURS hours ($MINUTES minutes)..."
    
    cd "$PROJECT_DIR"
    
    # Create the prompt content
    local PROMPT_CONTENT=$(cat "/tmp/claude-session-$SESSION_ID.txt")
    
    # Launch Claude Code with prompt
    log "Starting Claude Code..."
    
    # Start Claude in background and capture output
    (
        echo "$PROMPT_CONTENT" | claude 2>&1 | tee -a "$LOG_FILE"
    ) &
    
    CLAUDE_PID=$!
    
    log "Claude Code launched with PID: $CLAUDE_PID"
    log "Session will run for $MINUTES minutes"
    log ""
    log "Monitor progress: tail -f $LOG_FILE"
    log "Stop early: kill $CLAUDE_PID"
    log ""
    
    # Wait for specified duration
    local SECONDS_TO_WAIT=$((MINUTES * 60))
    local END_TIME=$(($(date +%s) + SECONDS_TO_WAIT))
    
    while [[ $(date +%s) -lt $END_TIME ]]; do
        if ! ps -p $CLAUDE_PID > /dev/null 2>&1; then
            warning "Claude process ended early"
            break
        fi
        
        # Show progress
        local REMAINING=$((END_TIME - $(date +%s)))
        local REMAINING_MIN=$((REMAINING / 60))
        echo -ne "\r⏱️  Time remaining: $REMAINING_MIN minutes    "
        
        sleep 30
    done
    
    echo ""
    log "Session time complete"
    
    # Kill Claude if still running
    if ps -p $CLAUDE_PID > /dev/null 2>&1; then
        log "Stopping Claude process..."
        kill $CLAUDE_PID 2>/dev/null || true
    fi
}

# Post-session
post_session() {
    log "Session complete!"
    
    # Generate summary
    local SUMMARY_FILE="$AUTOMATION_DIR/reports/summary-$SESSION_ID.md"
    
    cat > "$SUMMARY_FILE" << EOF
# Session Summary: $SESSION_ID

## Overview
- Duration: $HOURS hours ($MINUTES minutes)
- Start: $(head -1 "$LOG_FILE" 2>/dev/null | cut -d' ' -f2 || echo "Unknown")
- End: $(date)
- Project: $PROJECT_DIR
- Task File: $TASK_FILE

## Log File
$LOG_FILE

## Files in Project
$(ls -la "$PROJECT_DIR" 2>/dev/null || echo "Unable to list files")

## Next Steps
1. Review the log file for details
2. Check for any SUMMARY.md created by Claude
3. Verify task completion
EOF

    echo ""
    echo "📊 Session Summary saved to:"
    echo "$SUMMARY_FILE"
    echo ""
    echo "📋 Full log available at:"
    echo "$LOG_FILE"
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

# Check if bc is installed for decimal arithmetic
if ! command -v bc &> /dev/null; then
    echo "Installing bc for decimal arithmetic..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install bc 2>/dev/null || true
    fi
fi

main "$@"
