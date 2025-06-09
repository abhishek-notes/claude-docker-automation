#!/bin/bash

# Comprehensive test for iTerm notification system
echo "🧪 Testing Complete iTerm Notification System"
echo ""

echo "📋 Test Plan:"
echo "  1. Test notification trigger directly"
echo "  2. Test iTerm session launch with notifications"
echo "  3. Verify all notification types work"
echo ""

echo "📝 Test 1: Direct notification trigger"
./claude-notification-trigger.sh "Direct test - Claude notification working!" "Direct Test Session"
sleep 3

echo ""
echo "📝 Test 2: Launch Claude session with notification monitoring"
export CLAUDE_USE_TABS=true
export CLAUDE_ITERM_PROFILE="Automation"
echo "Starting Claude session - check for notifications when Claude starts..."
./claude-terminal-launcher.sh /Users/abhishek/Work/claude-docker-automation CLAUDE_TASKS.md &

echo ""
echo "✅ Notification system test launched!"
echo ""
echo "🔔 What to check:"
echo "  ✓ You should hear a bell sound"
echo "  ✓ You should see a macOS notification"
echo "  ✓ iTerm tab name should change to show project"
echo "  ✓ iTerm should activate/bring to front"
echo "  ✓ Session monitoring should start in background"
echo ""
echo "📊 Enabled features:"
echo "  • Bell sound notifications (\\a)"
echo "  • macOS notification center alerts"
echo "  • iTerm tab name updates"
echo "  • Automatic iTerm activation"
echo "  • Background session monitoring"
echo "  • 15-second delay before prompt paste"
echo "  • Automatic Enter key press"
echo ""
echo "💡 Monitoring:"
echo "  - Background process monitors Claude container"
echo "  - Sends notifications when Claude may need attention"
echo "  - Checks every 30 seconds while container is running"
echo "  - Waits 5 minutes between notification alerts"