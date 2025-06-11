#!/bin/bash

# Final test for iTerm profiles and Enter key functionality
echo "🧪 Final Test: iTerm Profiles + Enter Key + Tab Management"
echo ""

echo "📝 Test 1: First task (Palladio profile, new window)"
export CLAUDE_USE_TABS=true
export CLAUDE_ITERM_PROFILE="Palladio"
./claude-terminal-launcher.sh /Users/abhishek/Work/claude-docker-automation CLAUDE_TASKS.md &
sleep 8

echo "📝 Test 2: Second task (Work profile, new tab)"
export CLAUDE_ITERM_PROFILE="Work"
./claude-terminal-launcher.sh /Users/abhishek/Work/palladio-software-25 CLAUDE_TASKS.md &
sleep 8

echo "📝 Test 3: Third task (Automation profile, new tab)"
export CLAUDE_ITERM_PROFILE="Automation"
./claude-terminal-launcher.sh /Users/abhishek/Work/aralco-salesforce-migration CLAUDE_TASKS.md &
sleep 2

echo ""
echo "✅ All tests launched! Check iTerm for:"
echo "  ✓ First task: New window with Palladio profile"
echo "  ✓ Second task: New tab with Work profile"
echo "  ✓ Third task: New tab with Automation profile"
echo "  ✓ All tasks wait 15 seconds then paste prompt"
echo "  ✓ All tasks press Enter after pasting prompt"
echo "  ✓ Each task launches Claude in separate Docker container"

echo ""
echo "📊 Profile Testing Results:"
echo "  - Palladio: Should have Palladio colors/settings"
echo "  - Work: Should have Work colors/settings"  
echo "  - Automation: Should have Automation colors/settings"

echo ""
echo "⏱️ Timing:"
echo "  - 15 second delay before prompt paste"
echo "  - 1 second delay before Enter key"
echo "  - Tasks launch in parallel for quick testing"