#!/bin/bash

# Claude Terminal Launcher - Opens terminal and runs Claude with auto-paste
# Enhanced with safety features from claude-automation
set -euo pipefail

# Load safety system
AUTOMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$AUTOMATION_DIR/safety-system-restored.sh"

# Get parameters
PROJECT_PATH="${1:-$(pwd)}"
TASK_FILE="${2:-CLAUDE_TASKS.md}"

# Validate inputs
if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Project path does not exist: $PROJECT_PATH"
    exit 1
fi

if [ ! -f "$PROJECT_PATH/$TASK_FILE" ]; then
    echo "Error: Task file not found: $PROJECT_PATH/$TASK_FILE"
    exit 1
fi

# Read the task content
TASK_CONTENT=$(cat "$PROJECT_PATH/$TASK_FILE")

# Run pre-task safety check and create session
log_event "INFO" "Starting Claude terminal launcher for: $PROJECT_PATH"
SESSION_ID=$(pre_task_check "$PROJECT_PATH" "Terminal launcher task execution")

# Create the full prompt (same as claude-direct-task.sh)
FULL_PROMPT="You are Claude Code working in a Docker container. I need you to complete the tasks defined in $TASK_FILE.

TASK CONTENT FROM $TASK_FILE:
$TASK_CONTENT

WORKING INSTRUCTIONS:
1. Create a feature branch: claude/session-$SESSION_ID from main branch
2. Work systematically through EACH task listed above until completion
3. Create PROGRESS.md and update it after completing each major task
4. Commit changes frequently with meaningful messages
5. Test everything thoroughly as you build
6. Create comprehensive SUMMARY.md when ALL tasks are complete
7. Document any issues in ISSUES.md
8. Use proper git workflow (never commit directly to main)

GIT SETUP:
- Use 'main' as default branch
- Create feature branches for all work
- Make descriptive commit messages

COMPLETION CRITERIA:
- All tasks from $TASK_FILE are complete
- All tests pass (if applicable)
- Documentation is updated
- SUMMARY.md confirms completion

You have full permissions in this container. Work autonomously until all tasks are genuinely complete!

Please start by analyzing the project structure and then begin working on the first task."

# Escape the prompt for AppleScript
ESCAPED_PROMPT=$(printf '%s\n' "$FULL_PROMPT" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Get the automation directory
AUTOMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create AppleScript to open Terminal and run Claude
cat > /tmp/claude_terminal_launcher.scpt << EOF
tell application "Terminal"
    activate
    do script "cd '$AUTOMATION_DIR' && echo 'Starting Claude automation session...' && echo 'Project: $PROJECT_PATH' && echo 'Session ID: $SESSION_ID' && echo '' && ./claude-direct-task-restored.sh '$PROJECT_PATH' '$TASK_FILE'"
    delay 5
    do script "$ESCAPED_PROMPT" in front window
    delay 1
    tell application "System Events"
        key code 36
    end tell
end tell
EOF

# Run the AppleScript
osascript /tmp/claude_terminal_launcher.scpt

# Clean up
rm -f /tmp/claude_terminal_launcher.scpt

log_event "INFO" "Terminal launched successfully"
echo "✅ Terminal launched with Claude automation"
echo "📁 Project: $PROJECT_PATH"
echo "📋 Task file: $TASK_FILE"
echo "🆔 Session: $SESSION_ID"
echo "📊 Safety features: Backup created, session tracked"
echo "📝 Logs: $LOGS_DIR/safety-system.log"