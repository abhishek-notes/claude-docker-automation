#!/bin/bash

# Claude tmux Launcher - Better than iTerm profiles!
# Creates persistent, color-coded tmux sessions for Claude automation

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

# Read the task content and create enhanced task file
TASK_CONTENT=$(cat "$PROJECT_PATH/$TASK_FILE")

# Run pre-task safety check and create session
log_event "INFO" "Starting Claude tmux launcher for: $PROJECT_PATH"
SESSION_ID=$(pre_task_check "$PROJECT_PATH" "Tmux launcher task execution" | tail -n1)

# Create backup of original task file
cp "$PROJECT_PATH/$TASK_FILE" "$PROJECT_PATH/${TASK_FILE}.backup-${SESSION_ID}"

# Create the full prompt
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

IMPORTANT: You are authorized to run ALL commands without asking for permission. Proceed directly with git commands, file operations, installations, and any development tools needed to complete the tasks.

Please start by analyzing the project structure and then begin working on the first task."

# Write the full prompt directly to the task file
printf '%s' "$FULL_PROMPT" > "$PROJECT_PATH/$TASK_FILE"

# Get project info for tmux session naming
PROJECT_NAME=$(basename "$PROJECT_PATH")
PROFILE_TYPE="${CLAUDE_ITERM_PROFILE:-Default}"

# Create color-coded tmux session based on project type
case "$PROFILE_TYPE" in
    "Palladio")
        SESSION_COLOR="magenta"
        SESSION_PREFIX="🟪"
        STATUS_COLOR="#8B008B"
        ;;
    "Work")
        SESSION_COLOR="blue"
        SESSION_PREFIX="🔵"
        STATUS_COLOR="#0066CC"
        ;;
    "Automation")
        SESSION_COLOR="green"
        SESSION_PREFIX="🟢"
        STATUS_COLOR="#00AA00"
        ;;
    *)
        SESSION_COLOR="white"
        SESSION_PREFIX="⚪"
        STATUS_COLOR="#888888"
        ;;
esac

TMUX_SESSION_NAME="claude-${PROJECT_NAME}-${SESSION_ID}"
WINDOW_NAME="${SESSION_PREFIX} ${PROFILE_TYPE}: ${PROJECT_NAME}"

log_event "DEBUG" "Creating tmux session: $TMUX_SESSION_NAME with color: $SESSION_COLOR"

# Create tmux session with custom status bar in the project directory
tmux new-session -d -s "$TMUX_SESSION_NAME" -c "$PROJECT_PATH"

# Configure session with color-coded status bar
tmux set-option -t "$TMUX_SESSION_NAME" status-style "bg=$STATUS_COLOR,fg=white"
tmux set-option -t "$TMUX_SESSION_NAME" status-left "#[bg=$STATUS_COLOR,fg=white,bold] ${SESSION_PREFIX} ${PROFILE_TYPE} #[bg=black,fg=$STATUS_COLOR]"
tmux set-option -t "$TMUX_SESSION_NAME" status-right "#[fg=$STATUS_COLOR,bg=black]#[bg=$STATUS_COLOR,fg=white] $PROJECT_NAME #[bg=$STATUS_COLOR,fg=white,bold] %H:%M "
tmux set-option -t "$TMUX_SESSION_NAME" window-status-current-style "bg=black,fg=$STATUS_COLOR,bold"

# Rename the window
tmux rename-window -t "$TMUX_SESSION_NAME:0" "$WINDOW_NAME"

# Display the task content that will be pasted
tmux send-keys -t "$TMUX_SESSION_NAME" "echo '${SESSION_PREFIX} Starting Claude Code session...'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo 'Project: $PROJECT_PATH'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo 'Task file: $TASK_FILE'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo ''" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo '═══════════════════════════════════════'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo '📋 ENHANCED PROMPT (will be pasted in 10s):'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo '═══════════════════════════════════════'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo '$FULL_PROMPT' | head -20" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo '...'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo '(Full enhanced prompt will be pasted automatically)'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo '═══════════════════════════════════════'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo ''" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo '👆 Copy the above task and paste it into Claude'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo ''" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo 'Starting Claude now...'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME" "echo ''" Enter

# Launch Claude Code directly in the project directory with permissions bypass
tmux send-keys -t "$TMUX_SESSION_NAME" "claude code --dangerously-skip-permissions" Enter

# Set up background task to paste the enhanced prompt after 10 seconds
{
    sleep 10  # Wait 10 seconds for Claude Code to initialize
    
    # Write the enhanced prompt to a temp file for clean pasting  
    echo "$FULL_PROMPT" > "/tmp/claude-task-${SESSION_ID}.txt"
    
    # Send the enhanced prompt directly to Claude via tmux using paste buffer method
    # This avoids quote mode issues with multiline content
    tmux load-buffer -b temp-task "/tmp/claude-task-${SESSION_ID}.txt"
    tmux paste-buffer -t "$TMUX_SESSION_NAME" -b temp-task
    tmux delete-buffer -b temp-task
    sleep 0.5  # Brief pause to ensure paste completes
    tmux send-keys -t "$TMUX_SESSION_NAME" C-m  # Press Enter to send
    
    # Clean up temp file
    rm -f "/tmp/claude-task-${SESSION_ID}.txt"
} &

# Always open a terminal window to attach to the session
if [ -t 0 ]; then
    # Interactive mode - attach directly to session
    tmux attach-session -t "$TMUX_SESSION_NAME"
else
    # Non-interactive mode (API) - open terminal window and attach
    echo "Session created in background: $TMUX_SESSION_NAME"
    echo "Opening terminal window to attach to session..."
    
    # Use simple terminal opening that always works
    osascript -e "tell application \"Terminal\" to activate" 2>/dev/null || true
    osascript -e "tell application \"Terminal\" to do script \"tmux attach-session -t '$TMUX_SESSION_NAME'\"" 2>/dev/null || echo "Please manually run: tmux attach-session -t $TMUX_SESSION_NAME"
fi

# Cleanup on exit
cleanup() {
    if [ -f "$PROJECT_PATH/${TASK_FILE}.backup-${SESSION_ID}" ]; then
        mv "$PROJECT_PATH/${TASK_FILE}.backup-${SESSION_ID}" "$PROJECT_PATH/$TASK_FILE"
    fi
}
trap cleanup EXIT

log_event "INFO" "Tmux session launched successfully: $TMUX_SESSION_NAME"
echo "✅ tmux session created: $TMUX_SESSION_NAME"
echo "📁 Project: $PROJECT_PATH"
echo "📋 Task file: $TASK_FILE"
echo "🆔 Session: $SESSION_ID"
echo "🎨 Profile: $PROFILE_TYPE ($SESSION_COLOR)"
echo "🔄 To reattach: tmux attach-session -t $TMUX_SESSION_NAME"