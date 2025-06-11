#!/bin/bash

# Claude Interactive Launcher
# Handles the TTY requirement for Claude Code

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
if command -v bc &> /dev/null; then
    MINUTES=$(echo "$HOURS * 60" | bc)
    MINUTES=${MINUTES%.*}
else
    # Fallback for integer hours
    MINUTES=$((HOURS * 60))
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[WARNING] $1" >> "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[INFO] $1" >> "$LOG_FILE"
}

# Pre-flight checks
pre_flight_checks() {
    log "Running pre-flight checks..."
    
    # Check Claude Code installation
    if ! command -v claude &> /dev/null; then
        error "Claude Code not found. Install with: npm i -g @anthropic-ai/claude-code"
    fi
    
    # Check task file
    if [[ ! -f "$TASK_FILE" ]]; then
        warning "Task file not found. Creating from template..."
        mkdir -p "$(dirname "$TASK_FILE")"
        cp "$AUTOMATION_DIR/instructions/MASTER_TEMPLATE.md" "$TASK_FILE"
        info "Created task file: $TASK_FILE"
        info "Opening editor..."
        ${EDITOR:-nano} "$TASK_FILE"
        info "Task file ready. Run the launcher again to start."
        exit 0
    fi
    
    # Ensure directories exist
    mkdir -p "$LOG_DIR"
    mkdir -p "$AUTOMATION_DIR/backups"
    mkdir -p "$AUTOMATION_DIR/reports"
    mkdir -p "$AUTOMATION_DIR/work-sessions"
    
    log "Pre-flight checks complete ✓"
}

# Create instruction file for Claude
create_instruction_file() {
    local INSTRUCTION_FILE="$AUTOMATION_DIR/work-sessions/session-$SESSION_ID.md"
    local TASK_CONTENT=$(cat "$TASK_FILE")
    
    cat > "$INSTRUCTION_FILE" << EOF
# Autonomous Work Session

## Session Information
- Session ID: $SESSION_ID
- Duration: $HOURS hours ($MINUTES minutes)
- Start Time: $(date)
- Project Directory: $PROJECT_DIR
- Log File: $LOG_FILE

## Your Tasks

$TASK_CONTENT

## Session Instructions

1. **MCP Servers**: First run \`/mcp\` to check available MCP servers
2. **Work Directory**: You're in $PROJECT_DIR
3. **Progress Logging**: Create PROGRESS.md and update it every 15 minutes
4. **File Operations**: Use the filesystem MCP server when available

## Required Outputs

Create these files during your session:

1. **PROGRESS.md** - Update every 15 minutes with:
   - Current time
   - Tasks completed
   - Current task in progress
   - Any blockers

2. **SUMMARY.md** - At session end with:
   - List of all completed tasks
   - Files created/modified
   - Any issues encountered
   - Recommendations for next session

## Important Notes

- This is an autonomous session. Work independently.
- If you encounter permission prompts, note them in ISSUES.md
- Create a git commit after each major task (if in git repo)
- Test your code after implementation

Begin work now. Your session ends at $(date -d "+$MINUTES minutes" 2>/dev/null || date -v +${MINUTES}M).
EOF

    echo "$INSTRUCTION_FILE"
}

# Launch Claude in a new terminal (macOS)
launch_claude_terminal() {
    local INSTRUCTION_FILE=$(create_instruction_file)
    
    # Create launch script
    local LAUNCH_SCRIPT="$AUTOMATION_DIR/work-sessions/launch-$SESSION_ID.sh"
    cat > "$LAUNCH_SCRIPT" << EOF
#!/bin/bash
cd "$PROJECT_DIR"
echo "🚀 Starting Claude Code Session: $SESSION_ID"
echo "📋 Instructions at: $INSTRUCTION_FILE"
echo "📝 Log file: $LOG_FILE"
echo ""
echo "Claude will work autonomously for $HOURS hours."
echo "Check PROGRESS.md for updates."
echo ""

# Launch Claude with the instruction file as the first message
claude -p "Please read and follow the instructions in: $INSTRUCTION_FILE"

echo ""
echo "✅ Session complete! Check SUMMARY.md for results."
EOF

    chmod +x "$LAUNCH_SCRIPT"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - Use AppleScript to open new terminal
        osascript << EOF
tell application "Terminal"
    activate
    do script "cd '$PROJECT_DIR' && '$LAUNCH_SCRIPT' 2>&1 | tee -a '$LOG_FILE'"
end tell
EOF
        
        log "Claude Code launched in new Terminal window"
        log "Session will run for $HOURS hours ($MINUTES minutes)"
        
    else
        # Linux/Other - Try common terminal emulators
        if command -v gnome-terminal &> /dev/null; then
            gnome-terminal -- bash -c "cd '$PROJECT_DIR' && '$LAUNCH_SCRIPT' 2>&1 | tee -a '$LOG_FILE'; read -p 'Press enter to close...'"
        elif command -v xterm &> /dev/null; then
            xterm -e "cd '$PROJECT_DIR' && '$LAUNCH_SCRIPT' 2>&1 | tee -a '$LOG_FILE'; read -p 'Press enter to close...'"
        else
            warning "No suitable terminal found. Run manually:"
            echo "$LAUNCH_SCRIPT"
        fi
    fi
}

# Monitor session
monitor_session() {
    info "Session monitoring started"
    info "Check progress: tail -f $PROJECT_DIR/PROGRESS.md"
    info "View logs: tail -f $LOG_FILE"
    
    # Create a monitoring script
    cat > "$AUTOMATION_DIR/work-sessions/monitor-$SESSION_ID.sh" << EOF
#!/bin/bash
echo "📊 Monitoring Session: $SESSION_ID"
echo "================================"
echo ""

# Function to check file updates
check_file() {
    if [[ -f "\$1" ]]; then
        echo "📄 \$1 - Last updated: \$(stat -f "%Sm" "\$1" 2>/dev/null || stat -c "%y" "\$1" 2>/dev/null || echo "Unknown")"
    else
        echo "⏳ \$1 - Not created yet"
    fi
}

cd "$PROJECT_DIR"

while true; do
    clear
    echo "📊 Session Monitor: $SESSION_ID"
    echo "Time: \$(date)"
    echo "================================"
    echo ""
    
    check_file "PROGRESS.md"
    check_file "SUMMARY.md"
    check_file "ISSUES.md"
    
    echo ""
    echo "📁 Recent files:"
    ls -lt | head -5
    
    echo ""
    echo "Press Ctrl+C to stop monitoring"
    
    sleep 30
done
EOF

    chmod +x "$AUTOMATION_DIR/work-sessions/monitor-$SESSION_ID.sh"
    
    echo ""
    echo "🔍 To monitor progress, run:"
    echo "   $AUTOMATION_DIR/work-sessions/monitor-$SESSION_ID.sh"
}

# Generate final report
generate_report() {
    local REPORT_FILE="$AUTOMATION_DIR/reports/report-$SESSION_ID.md"
    
    cat > "$REPORT_FILE" << EOF
# Session Report: $SESSION_ID

## Overview
- Date: $(date +%Y-%m-%d)
- Duration: $HOURS hours
- Task File: $TASK_FILE
- Project: $PROJECT_DIR

## Files Created
$(cd "$PROJECT_DIR" && find . -name "*.md" -newer "$TASK_FILE" -type f 2>/dev/null | head -20 || echo "No new files found")

## Session Artifacts
- Instructions: $AUTOMATION_DIR/work-sessions/session-$SESSION_ID.md
- Launch Script: $AUTOMATION_DIR/work-sessions/launch-$SESSION_ID.sh
- Monitor Script: $AUTOMATION_DIR/work-sessions/monitor-$SESSION_ID.sh
- Log File: $LOG_FILE

## Next Steps
1. Review SUMMARY.md in the project directory
2. Check PROGRESS.md for detailed timeline
3. Address any items in ISSUES.md
EOF

    info "Report saved to: $REPORT_FILE"
}

# Main execution
main() {
    echo -e "${GREEN}🤖 Claude Autonomous Session Launcher${NC}"
    echo "====================================="
    echo ""
    
    pre_flight_checks
    launch_claude_terminal
    monitor_session
    
    echo ""
    echo "✅ Session launched successfully!"
    echo ""
    echo "📋 Session ID: $SESSION_ID"
    echo "⏱️  Duration: $HOURS hours"
    echo "📁 Working in: $PROJECT_DIR"
    echo ""
    
    generate_report
}

# Run
main "$@"
