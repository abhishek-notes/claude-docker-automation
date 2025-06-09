#!/bin/bash

# Claude Notification Trigger - Call this when Claude needs attention
# Usage: ./claude-notification-trigger.sh "message" [session_name]

set -e

MESSAGE="${1:-Claude needs attention}"
SESSION_NAME="${2:-Claude Session}"
PROJECT_PATH="${3:-$(pwd)}"

# Send notification through multiple channels
echo "🔔 Sending Claude notification..."

# 1. Terminal bell
echo -e "\a"

# 2. Visual notification via iTerm AppleScript
cat > /tmp/claude_notify.scpt << EOF
tell application "iTerm"
    activate
    if (count of windows) > 0 then
        tell current window
            if (count of tabs) > 0 then
                tell current session of current tab
                    set name to "$SESSION_NAME - ATTENTION NEEDED"
                end tell
            end if
        end tell
    end if
end tell

display notification "$MESSAGE" with title "Claude Code Alert" subtitle "$SESSION_NAME" sound name "Ping"
EOF

osascript /tmp/claude_notify.scpt
rm -f /tmp/claude_notify.scpt

# 3. Dock bounce (if iTerm not active)
if ! pgrep -f "iTerm" > /dev/null; then
    osascript -e 'tell application "iTerm" to activate'
fi

# 4. Log the notification
echo "[$(date '+%Y-%m-%d %H:%M:%S')] NOTIFICATION: $MESSAGE - $SESSION_NAME" >> /Users/abhishek/Work/claude-docker-automation/logs/notifications.log

echo "✅ Notification sent: $MESSAGE"