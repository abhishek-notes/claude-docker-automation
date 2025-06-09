#!/bin/bash

# Test multiple simultaneous Claude tasks with different iTerm profiles
echo "🧪 Testing multiple simultaneous Claude tasks..."

# Test with different projects and profiles
echo "📝 Starting first task (Default profile)..."
export CLAUDE_USE_TABS=true
export CLAUDE_ITERM_PROFILE="Default"
./claude-terminal-launcher.sh /Users/abhishek/Work/claude-docker-automation CLAUDE_TASKS.md &
sleep 5

echo "📝 Starting second task (Claude profile - if available)..."
export CLAUDE_ITERM_PROFILE="Claude"
./claude-terminal-launcher.sh /Users/abhishek/Work/palladio-software-25 CLAUDE_TASKS.md &
sleep 5

echo "📝 Starting third task (Different profile)..."
export CLAUDE_ITERM_PROFILE="Development"
./claude-terminal-launcher.sh /Users/abhishek/Work/aralco-salesforce-migration CLAUDE_TASKS.md &
sleep 2

echo "✅ Test launched! Check iTerm for:"
echo "  - Multiple tabs should be created"
echo "  - Each tab should use different profile (if profiles exist)"
echo "  - Each task should launch Claude in separate Docker containers"
echo "  - Should wait 15 seconds before pasting prompts"

echo ""
echo "📊 Environment variables used:"
echo "  CLAUDE_USE_TABS=true (use tabs)"
echo "  CLAUDE_ITERM_PROFILE=Default/Claude/Development"
echo ""
echo "💡 Note:"
echo "  - If profiles don't exist, will fallback to default"
echo "  - Each task runs in separate Docker container"
echo "  - Tasks run simultaneously for testing tab management"