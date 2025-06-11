#!/bin/bash
cd "/Users/abhishek/Work/claude-automation"
echo "🚀 Starting Claude Code Session: session-20250605-051029"
echo "📋 Instructions at: /Users/abhishek/Work/claude-automation/work-sessions/session-session-20250605-051029.md"
echo "📝 Log file: /Users/abhishek/Work/claude-automation/logs/session-20250605-051029.log"
echo ""
echo "Claude will work autonomously for 1 hours."
echo "Check PROGRESS.md for updates."
echo ""

# Launch Claude with the instruction file as the first message
claude -p "Please read and follow the instructions in: /Users/abhishek/Work/claude-automation/work-sessions/session-session-20250605-051029.md"

echo ""
echo "✅ Session complete! Check SUMMARY.md for results."
