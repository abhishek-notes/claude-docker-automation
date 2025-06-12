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

# Check task file in both locations
AUTOMATION_TASK_PATH="/workspace/automation/claude-docker-automation/$TASK_FILE"
PROJECT_TASK_PATH="$PROJECT_PATH/$TASK_FILE"

if [ -f "$AUTOMATION_TASK_PATH" ]; then
    TASK_PATH="$AUTOMATION_TASK_PATH"
    echo "Found task file in automation folder: $TASK_PATH"
elif [ -f "$PROJECT_TASK_PATH" ]; then
    TASK_PATH="$PROJECT_TASK_PATH"
    echo "Found task file in project folder: $TASK_PATH"
else
    echo "Error: Task file not found in either location:"
    echo "  - $AUTOMATION_TASK_PATH"
    echo "  - $PROJECT_TASK_PATH"
    echo "Please create $TASK_FILE in /workspace/automation/claude-docker-automation/"
    exit 1
fi

# Read the task content and create enhanced task file
TASK_CONTENT=$(cat "$TASK_PATH")

# Run pre-task safety check and create session
log_event "INFO" "Starting Claude tmux launcher for: $PROJECT_PATH"
SESSION_ID=$(pre_task_check "$PROJECT_PATH" "Tmux launcher task execution" | tail -n1)

# Keep original task file unchanged to prevent auto-injection issues

# Create the full prompt with improved methodology
FULL_PROMPT="You are Claude Code working autonomously in a persistent Docker container. Complete ALL tasks defined below.

TASK FILE CONTENT FROM $TASK_FILE:
$TASK_CONTENT

CRITICAL: UNDERSTAND THE TASK FIRST!

⚠️ DO NOT CREATE FILES FOR SIMPLE RESPONSES!

Decision Flow:
┌─► Is this a simple response task? (greeting, calculation, one-line answer)
│   └─► YES → Output the response directly. NO files, NO git, NO branches!
│   └─► NO → Continue to task classification below

Task Classification:
- Simple Response: "respond with", "what is" → Just print answer
- Analysis: "explain", "review" → Read and report only
- Implementation: "create", "build" → Follow full workflow
- Fix: "fix", "update" → Modify specific files only

WORKING INSTRUCTIONS:
1. ANALYZE THE ACTUAL REQUIREMENT using the classification above
   - Simple responses = output text only
   - Only create files/code if task explicitly requires implementation
2. For implementation tasks:
   - Create feature branch: claude/session-$SESSION_ID from main
   - Work systematically through EACH task until completion
   - Create PROGRESS.md and update after each major milestone (if needed)
   - Commit changes frequently with descriptive messages
   - Test everything thoroughly as you build
   - Create comprehensive SUMMARY.md when ALL tasks complete
   - Document any issues in ISSUES.md
   - Use proper git workflow (never commit to main)

GIT WORKFLOW:
- Initialize repo if needed (git init)
- Create and work on feature branch
- Make frequent commits with clear messages
- Merge to main only when everything is complete

COMPLETION CRITERIA:
- All tasks from $TASK_FILE are complete and working
- All tests pass (if applicable)
- Documentation is updated
- SUMMARY.md confirms completion with proof of working solution

AUTONOMOUS MODE: Work completely independently. Don't ask for confirmation or input. Just complete the tasks and document your progress.

NOTE: This is an ephemeral container for security isolation. Your work files are preserved on the host filesystem, but the container will auto-remove when you exit.

BEGIN AUTONOMOUS WORK NOW!"

# DO NOT overwrite the original task file - this causes auto-injection issues
# The full prompt will be available for manual pasting only

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

# FIX: Create tmux session with Claude Code as the PRIMARY process (not subprocess of shell)
# This prevents shell from intercepting task content before Claude is ready
tmux new-session -d -s "$TMUX_SESSION_NAME" -c "$PROJECT_PATH" -n "claude" "exec claude --dangerously-skip-permissions"

# Configure session with color-coded status bar
tmux set-option -t "$TMUX_SESSION_NAME" status-style "bg=$STATUS_COLOR,fg=white"
tmux set-option -t "$TMUX_SESSION_NAME" status-left "#[bg=$STATUS_COLOR,fg=white,bold] ${SESSION_PREFIX} ${PROFILE_TYPE} #[bg=black,fg=$STATUS_COLOR]"
tmux set-option -t "$TMUX_SESSION_NAME" status-right "#[fg=$STATUS_COLOR,bg=black]#[bg=$STATUS_COLOR,fg=white] $PROJECT_NAME #[bg=$STATUS_COLOR,fg=white,bold] %H:%M "
tmux set-option -t "$TMUX_SESSION_NAME" window-status-current-style "bg=black,fg=$STATUS_COLOR,bold"

# Create separate window for information/instructions (not the Claude window)
tmux new-window -t "$TMUX_SESSION_NAME" -n "info" -c "$PROJECT_PATH"

# Display instructions in the info window (window 1, not Claude window 0)
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '${SESSION_PREFIX} Claude Code session ready'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo 'Project: $PROJECT_PATH'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo 'Task file: $TASK_FILE'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo ''" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '═══════════════════════════════════════'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '📋 ENHANCED PROMPT (ready for manual paste):'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '═══════════════════════════════════════'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '$FULL_PROMPT' | head -20" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '...'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '(Full enhanced prompt ready for manual paste)'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '═══════════════════════════════════════'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo ''" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '✅ Claude Code is running in window 0'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '📋 Task content loaded into tmux buffer'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '🔄 Switch to Claude window: Ctrl+B 0'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '📥 Paste when ready: Ctrl+B ]'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo ''" Enter

# Save task content to temp file for manual pasting when Claude is ready
TASK_FILE_PATH="/tmp/claude-task-${SESSION_ID}.txt"
echo "$FULL_PROMPT" > "$TASK_FILE_PATH"

# Display additional instructions in the info window
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '🔴 IMPORTANT: Claude runs as primary process (no shell interference)'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo ''" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo 'How to use:'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '1. Switch to Claude window: Ctrl+B 0'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '2. Wait for Claude prompt to appear'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '3. Paste task content: Ctrl+B ]'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '4. Press Enter to send'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo ''" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo 'Task file saved to: $TASK_FILE_PATH'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo ''" Enter

# Pre-load the task content into tmux paste buffer for easy manual pasting
tmux load-buffer -b claude-task "$TASK_FILE_PATH"

# Final status in info window
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '✅ Task content loaded into tmux buffer'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '🚀 Ready to paste when Claude shows prompt!'" Enter
tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo ''" Enter

# Optional intelligent auto-paste that waits for Claude's prompt
AUTO_PASTE="${CLAUDE_AUTO_PASTE:-false}"
if [ "$AUTO_PASTE" = "true" ]; then
    tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '⚠️  Auto-paste enabled - will wait for Claude prompt'" Enter
    tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo ''" Enter
    
    # Background task that waits for Claude's prompt before pasting
    {
        echo "Auto-paste: waiting for Claude prompt to appear..." >&2
        
        # Function to wait for Claude's prompt (ChatGPT's suggestion)
        wait_for_claude() {
            local max_wait=300  # 5 minutes maximum wait
            local count=0
            while [ $count -lt $max_wait ]; do
                sleep 0.3
                # Look for Claude's prompt indicators in window 0 (Claude window)
                if tmux capture-pane -pt "$TMUX_SESSION_NAME:0" -S -50 | grep -q -E "(Assistant|claude|>|$)"; then
                    echo "Claude prompt detected, pasting task content..." >&2
                    return 0
                fi
                count=$((count + 1))
                if [ $((count % 10)) -eq 0 ]; then
                    echo "Still waiting for Claude prompt... ($((count/10))0s)" >&2
                fi
            done
            echo "Timeout waiting for Claude prompt, pasting anyway..." >&2
            return 1
        }
        
        # Wait for Claude prompt then paste
        wait_for_claude
        tmux paste-buffer -t "$TMUX_SESSION_NAME:0" -b claude-task 2>/dev/null || {
            echo "Auto-paste failed: buffer not available" >&2
        }
        sleep 0.5
        tmux send-keys -t "$TMUX_SESSION_NAME:0" C-m  # Press Enter to send
        
        echo "Auto-paste completed successfully" >&2
    } &
else
    tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo '💡 Tip: Set CLAUDE_AUTO_PASTE=true to enable intelligent auto-paste'" Enter
    tmux send-keys -t "$TMUX_SESSION_NAME:1" "echo ''" Enter
fi

# Always open a terminal window to attach to the session
if [ -t 0 ]; then
    # Interactive mode - attach directly to Claude window (window 0)
    log_event "INFO" "Interactive mode detected - attaching to tmux Claude window"
    tmux attach-session -t "$TMUX_SESSION_NAME:0"
else
    # Non-interactive mode (API) - open terminal window and attach
    log_event "INFO" "Non-interactive mode detected - will open iTerm"
    echo "Session created in background: $TMUX_SESSION_NAME"
    echo "Opening terminal window to attach to session..."
    
    # Check if we should open in new tab (default) or existing tab
    open_new_tab="${CLAUDE_OPEN_NEW_TAB:-true}"
    
    log_event "DEBUG" "Terminal mode detected. Open new tab: $open_new_tab"
    
    if [ "$open_new_tab" = "true" ]; then
        # Open in new iTerm tab (default behavior)
        log_event "DEBUG" "Attempting to open new iTerm tab..."
        if command -v osascript >/dev/null 2>&1; then
            # Run AppleScript directly
            osascript -e "
            tell application \"iTerm\"
                activate
                if (count of windows) is 0 then
                    set targetWindow to (create window with default profile)
                else
                    set targetWindow to current window
                    tell targetWindow
                        create tab with default profile
                    end tell
                end if
                
                tell targetWindow
                    tell last tab
                        tell current session
                            set name to \"$WINDOW_NAME\"
                            write text \"tmux attach-session -t '$TMUX_SESSION_NAME:0'\"
                        end tell
                    end tell
                end tell
            end tell
            " 2>&1 || {
                    # Fallback to Terminal if iTerm not available
                    log_event "DEBUG" "iTerm AppleScript failed, falling back to Terminal"
                    osascript -e "tell application \"Terminal\" to activate" 2>/dev/null || true
                    osascript -e "tell application \"Terminal\" to do script \"tmux attach-session -t '$TMUX_SESSION_NAME:0'\"" 2>/dev/null || echo "Please manually run: tmux attach-session -t $TMUX_SESSION_NAME:0"
                }
            log_event "DEBUG" "iTerm AppleScript execution completed"
        else
            log_event "DEBUG" "osascript not available, manual attach required"
            echo "Please manually run: tmux attach-session -t $TMUX_SESSION_NAME:0"
        fi
    else
        # Use existing tab/window behavior
        log_event "DEBUG" "Using existing tab mode"
        if command -v osascript >/dev/null 2>&1; then
            # Run AppleScript in background to avoid blocking
            {
                osascript -e "
            tell application \"iTerm\"
                activate
                if (count of windows) is 0 then
                    set targetWindow to (create window with default profile)
                else
                    set targetWindow to current window
                end if
                
                tell targetWindow
                    tell current session of current tab
                        set name to \"$WINDOW_NAME\"
                        write text \"tmux attach-session -t '$TMUX_SESSION_NAME:0'\"
                    end tell
                end tell
            end tell
            " 2>&1 || {
                    # Fallback to Terminal if iTerm not available
                    log_event "DEBUG" "iTerm AppleScript failed, falling back to Terminal"
                    osascript -e "tell application \"Terminal\" to activate" 2>/dev/null || true
                    osascript -e "tell application \"Terminal\" to do script \"tmux attach-session -t '$TMUX_SESSION_NAME'\"" 2>/dev/null || echo "Please manually run: tmux attach-session -t $TMUX_SESSION_NAME"
                }
            } &
            log_event "DEBUG" "iTerm AppleScript launched in background"
        else
            log_event "DEBUG" "osascript not available, manual attach required"
            echo "Please manually run: tmux attach-session -t $TMUX_SESSION_NAME"
        fi
    fi
fi

# Cleanup on exit
cleanup() {
    # Clean up temp task file if it exists
    if [ -f "$TASK_FILE_PATH" ]; then
        rm -f "$TASK_FILE_PATH"
    fi
}
trap cleanup EXIT

log_event "INFO" "Tmux session launched successfully: $TMUX_SESSION_NAME"
echo "✅ tmux session created: $TMUX_SESSION_NAME"
echo "📁 Project: $PROJECT_PATH"
echo "📋 Task file: $TASK_FILE"
echo "🆔 Session: $SESSION_ID"
echo "🎨 Profile: $PROFILE_TYPE ($SESSION_COLOR)"
echo "🔄 To reattach: tmux attach-session -t $TMUX_SESSION_NAME:0"
echo "📱 Info window: tmux attach-session -t $TMUX_SESSION_NAME:1"