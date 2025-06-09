#!/bin/bash

# Test frontend profile integration
echo "🧪 Testing Frontend Profile Integration"
echo ""

# Check if task API server is running
if ! curl -s http://localhost:3456/api/health > /dev/null; then
    echo "❌ Task API server not running. Starting it..."
    node task-api.js &
    sleep 3
fi

echo "✅ Task API server is running"
echo ""

echo "🌐 Frontend Integration Test:"
echo "1. Open your browser to: http://localhost:3456"
echo "2. Fill in project path (e.g., /Users/abhishek/Work/palladio-software-25)"
echo "3. Notice how iTerm Profile auto-selects based on path:"
echo "   • 'palladio' → Palladio profile"
echo "   • 'automation' or 'claude' → Automation profile"
echo "   • 'work' or 'api' → Work profile"
echo "   • Others → Default profile"
echo ""
echo "4. Create a task and launch it"
echo "5. Verify iTerm opens with the correct profile colors/settings"

echo ""
echo "🔧 Manual Test Commands:"
echo ""

# Test with Palladio profile
echo "Test 1: Palladio Profile"
echo "curl -X POST http://localhost:3456/api/launch-task \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{"
echo "    \"projectPath\": \"/Users/abhishek/Work/palladio-software-25\","
echo "    \"taskContent\": \"Test task for Palladio profile\","
echo "    \"sessionId\": \"test-palladio-$(date +%s)\","
echo "    \"itermProfile\": \"Palladio\""
echo "  }'"

echo ""

# Test with Work profile  
echo "Test 2: Work Profile"
echo "curl -X POST http://localhost:3456/api/launch-task \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{"
echo "    \"projectPath\": \"/Users/abhishek/Work/test-project\","
echo "    \"taskContent\": \"Test task for Work profile\","
echo "    \"sessionId\": \"test-work-$(date +%s)\","
echo "    \"itermProfile\": \"Work\""
echo "  }'"

echo ""

# Test with Automation profile
echo "Test 3: Automation Profile"
echo "curl -X POST http://localhost:3456/api/launch-task \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{"
echo "    \"projectPath\": \"/Users/abhishek/Work/claude-docker-automation\","
echo "    \"taskContent\": \"Test task for Automation profile\","
echo "    \"sessionId\": \"test-automation-$(date +%s)\","
echo "    \"itermProfile\": \"Automation\""
echo "  }'"

echo ""
echo "💡 What to verify:"
echo "  ✓ iTerm opens with correct profile colors"
echo "  ✓ Tab names show project names"
echo "  ✓ Multiple tasks open in tabs (not windows)"
echo "  ✓ 15-second delay before prompt paste"
echo "  ✓ Automatic Enter key press"
echo "  ✓ Notification system working"

echo ""
echo "🔍 Check Environment Variables:"
echo "ps aux | grep claude-terminal-launcher"
echo "Should show: CLAUDE_ITERM_PROFILE=ProfileName CLAUDE_USE_TABS=true"