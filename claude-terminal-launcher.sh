#!/bin/bash

# Claude Terminal Launcher - Opens terminal and runs Claude with auto-paste
# Enhanced with safety features from claude-automation
set -euo pipefail

# Load safety system
AUTOMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$AUTOMATION_DIR/safety-system.sh"

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
SESSION_ID=$(pre_task_check "$PROJECT_PATH" "Terminal launcher task execution" | tail -n1)

# Create backup of original task file
cp "$PROJECT_PATH/$TASK_FILE" "$PROJECT_PATH/${TASK_FILE}.backup-${SESSION_ID}"

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

# Write the full prompt directly to the task file so Docker can access it
printf '%s' "$FULL_PROMPT" > "$PROJECT_PATH/$TASK_FILE"

# Get the automation directory
AUTOMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we need a new window or can use existing tab
USE_NEW_TAB="${CLAUDE_USE_TABS:-true}"
ITERM_PROFILE="${CLAUDE_ITERM_PROFILE:-Default}"
PROJECT_NAME=$(basename "$PROJECT_PATH")

# Visual test: Green emoji tab naming for claude-docker-automation 
TAB_NAME="🟢 GREEN: claude-docker-automation"

# Debug environment variables
log_event "DEBUG" "Environment: CLAUDE_USE_TABS=$CLAUDE_USE_TABS, CLAUDE_ITERM_PROFILE=$ITERM_PROFILE"
log_event "DEBUG" "Resolved: USE_NEW_TAB=$USE_NEW_TAB, TAB_NAME=$TAB_NAME"

# Create AppleScript with proper variable substitution
if [ "$USE_NEW_TAB" = "true" ]; then
    TAB_CONDITION="true"
else
    TAB_CONDITION="false"
fi

cat > /tmp/claude_terminal_launcher.scpt << EOF
tell application "iTerm"
    activate
    
    if $TAB_CONDITION and (count of windows) > 0 then
        -- Use existing window, create new tab with explicit profile
        tell current window
            set newTab to (create tab with profile "$ITERM_PROFILE")
            tell current session of newTab
                -- Set simple tab name
                set name to "$TAB_NAME"
                
                -- Set iTerm2 badge that persists even when Claude Code takes over
                set badge to "$ITERM_PROFILE"
                
                -- Visual test: Green header output
                write text "echo -e '\\033[0;32m==== 🟢 GREEN: CLAUDE DOCKER AUTOMATION ====\\033[0m'"
                write text "echo -e '\\033[0;32mProject: $PROJECT_PATH\\033[0m'"
                write text "echo -e '\\033[0;32mProfile: $ITERM_PROFILE\\033[0m'"
                write text "echo -e '\\033[0;32m===========================================\\033[0m'"
                write text "cd '$AUTOMATION_DIR' && ./claude-direct-task.sh '$PROJECT_PATH' '$TASK_FILE'"
                delay 15
                write text "cat $TASK_FILE"
                delay 1
                tell application "System Events"
                    key code 36
                end tell
            end tell
        end tell
    else
        -- Create new window with explicit profile
        set newWindow to (create window with profile "$ITERM_PROFILE")
        tell current session of newWindow
            -- Set simple tab name
            set name to "$TAB_NAME"
            
            -- Set iTerm2 badge that persists even when Claude Code takes over
            set badge to "$ITERM_PROFILE"
            
            -- Visual test: Green header output
            write text "echo -e '\\033[0;32m==== 🟢 GREEN: CLAUDE DOCKER AUTOMATION ====\\033[0m'"
            write text "echo -e '\\033[0;32mProject: $PROJECT_PATH\\033[0m'"
            write text "echo -e '\\033[0;32mProfile: $ITERM_PROFILE\\033[0m'"
            write text "echo -e '\\033[0;32m===========================================\\033[0m'"
            write text "cd '$AUTOMATION_DIR' && ./claude-direct-task.sh '$PROJECT_PATH' '$TASK_FILE'"
            delay 15
            write text "cat $TASK_FILE"
            delay 1
            tell application "System Events"
                key code 36
            end tell
        end tell
    end if
end tell
EOF

# Run the AppleScript
osascript /tmp/claude_terminal_launcher.scpt

# Clean up  
rm -f /tmp/claude_terminal_launcher.scpt

# Add cleanup trap to restore original task file on exit
cleanup() {
    if [ -f "$PROJECT_PATH/${TASK_FILE}.backup-${SESSION_ID}" ]; then
        mv "$PROJECT_PATH/${TASK_FILE}.backup-${SESSION_ID}" "$PROJECT_PATH/$TASK_FILE"
    fi
}
trap cleanup EXIT

log_event "INFO" "Terminal launched successfully"
echo "iTerm launched with Claude automation"
echo "Project: $PROJECT_PATH"
echo "Task file: $TASK_FILE"
echo "Session: $SESSION_ID"
echo "Safety features: Backup created, session tracked"
echo "Logs: $LOGS_DIR/safety-system.log"