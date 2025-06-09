#!/bin/bash

echo "🧪 Comprehensive iTerm Profile Test"
echo "==================================="
echo ""

echo "Testing all profiles through frontend API..."
echo ""

# Test each profile
profiles=("Default" "Palladio" "Work" "Automation")

for profile in "${profiles[@]}"; do
    echo "🔍 Testing profile: $profile"
    
    session_id="test-$profile-$(date +%s)"
    
    response=$(curl -s -X POST http://localhost:3456/api/launch-task \
      -H 'Content-Type: application/json' \
      -d "{
        \"projectPath\": \"/Users/abhishek/Work/claude-docker-automation\",
        \"taskContent\": \"# Profile Test: $profile\\n\\nThis tests the $profile iTerm profile.\\n\\n## Task\\n1. Verify profile colors and settings\\n2. Check tab name shows: $profile Profile Test\",
        \"sessionId\": \"$session_id\",
        \"itermProfile\": \"$profile\"
      }")
    
    echo "   Response: $response"
    echo "   Check iTerm for new tab with $profile profile"
    echo "   Tab name should be: Claude: claude-docker-automation"
    echo ""
    
    # Wait between tests
    sleep 3
done

echo ""
echo "🔍 Debug Information:"
echo "Check the safety system logs for environment debug info:"
echo "tail -20 logs/safety-system.log | grep -E '(DEBUG|Environment|CLAUDE_ITERM_PROFILE)'"
echo ""
echo "Expected behavior:"
echo "✓ Each test should open a new tab (not window)"
echo "✓ Each tab should have different colors/settings based on profile"
echo "✓ Tab names should all show 'Claude: claude-docker-automation'"
echo "✓ Logs should show the correct CLAUDE_ITERM_PROFILE for each test"
echo ""
echo "Visual differences to look for:"
echo "• Default: iTerm's default colors"
echo "• Palladio: Should have distinct colors if configured"
echo "• Work: Should have distinct colors if configured"  
echo "• Automation: Should have distinct colors if configured"