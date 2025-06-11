#!/bin/bash

# Test script to check environment variable propagation

echo "=== Environment Test ==="
echo "CLAUDE_ITERM_PROFILE: ${CLAUDE_ITERM_PROFILE:-NOT_SET}"
echo "CLAUDE_USE_TABS: ${CLAUDE_USE_TABS:-NOT_SET}"
echo ""

# Test actual call chain
echo "=== Testing Call Chain ==="
echo "1. Testing API → Wrapper → Launcher chain..."

# Simulate the call that happens from task-api.js
CLAUDE_ITERM_PROFILE="TestProfile" CLAUDE_USE_TABS="true" ./claude-terminal-launcher.sh /Users/abhishek/Work/claude-docker-automation CLAUDE_TASKS.md