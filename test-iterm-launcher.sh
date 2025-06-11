#!/bin/bash

# Test script for iTerm integration
# This tests both new window and tab creation scenarios

echo "🧪 Testing iTerm integration..."

# Test 1: First launch (should create new window)
echo "📝 Test 1: First launch (new window)"
export CLAUDE_USE_TABS=false
./claude-terminal-launcher.sh /Users/abhishek/Work/claude-docker-automation CLAUDE_TASKS.md &
sleep 10

# Test 2: Second launch (should create new tab)
echo "📝 Test 2: Second launch (new tab)"
export CLAUDE_USE_TABS=true
./claude-terminal-launcher.sh /Users/abhishek/Work/claude-docker-automation CLAUDE_TASKS.md &
sleep 10

echo "✅ Test completed! Check iTerm for:"
echo "  - First instance should open in new window"
echo "  - Second instance should open in new tab"
echo "  - Both should launch Claude in Docker containers"

echo ""
echo "📊 Environment variables:"
echo "  CLAUDE_USE_TABS=${CLAUDE_USE_TABS:-true} (controls tab behavior)"
echo ""
echo "💡 Tips:"
echo "  - Set CLAUDE_USE_TABS=false to always use new windows"
echo "  - Set CLAUDE_USE_TABS=true to use tabs when possible (default)"