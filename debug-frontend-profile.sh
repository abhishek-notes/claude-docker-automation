#!/bin/bash

# Debug frontend profile issue

echo "🔍 Testing Frontend Profile Integration"
echo ""

# Test direct API call with profile
echo "Testing API call with Palladio profile..."

curl -X POST http://localhost:3456/api/launch-task \
  -H 'Content-Type: application/json' \
  -d '{
    "projectPath": "/Users/abhishek/Work/claude-docker-automation",
    "taskContent": "# Test Task\n\nThis is a test task to verify profile integration.\n\n## Tasks\n1. Test profile application\n2. Check environment variables",
    "sessionId": "debug-test-'$(date +%s)'",
    "itermProfile": "Palladio"
  }'

echo ""
echo ""
echo "Check the iTerm window that just opened:"
echo "1. Does it have Palladio profile colors/settings?"
echo "2. Check the session logs for environment variables"
echo ""
echo "To check session logs:"
echo "tail -f logs/safety-system.log | grep -E '(DEBUG|Environment|CLAUDE_ITERM_PROFILE)'"