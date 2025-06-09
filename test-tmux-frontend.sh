#!/bin/bash

echo "🎯 Testing New tmux-based Frontend System"
echo "========================================="
echo ""

echo "Testing different session types via API..."
echo ""

# Test 1: Work session
echo "1️⃣ Creating Work session (🔵 blue status bar)..."
curl -s -X POST http://localhost:3456/api/launch-task \
  -H 'Content-Type: application/json' \
  -d '{
    "projectPath": "/Users/abhishek/Work/claude-docker-automation",
    "taskContent": "# tmux Test: Work Session\n\nTesting Work session type with blue theme.\n\n## Tasks\n1. Verify blue status bar in tmux\n2. Check session persistence\n3. Test detach/reattach capability",
    "sessionId": "tmux-work-'$(date +%s)'",
    "itermProfile": "Work"
  }' | jq -r '.message // .error'

sleep 3

# Test 2: Palladio session  
echo ""
echo "2️⃣ Creating Palladio session (🟪 purple status bar)..."
curl -s -X POST http://localhost:3456/api/launch-task \
  -H 'Content-Type: application/json' \
  -d '{
    "projectPath": "/Users/abhishek/Work/claude-docker-automation",
    "taskContent": "# tmux Test: Palladio Session\n\nTesting Palladio session type with purple theme.\n\n## Tasks\n1. Verify purple status bar in tmux\n2. Check window naming\n3. Test session recovery",
    "sessionId": "tmux-palladio-'$(date +%s)'",
    "itermProfile": "Palladio"
  }' | jq -r '.message // .error'

sleep 3

# Test 3: Automation session
echo ""
echo "3️⃣ Creating Automation session (🟢 green status bar)..."  
curl -s -X POST http://localhost:3456/api/launch-task \
  -H 'Content-Type: application/json' \
  -d '{
    "projectPath": "/Users/abhishek/Work/claude-docker-automation",
    "taskContent": "# tmux Test: Automation Session\n\nTesting Automation session type with green theme.\n\n## Tasks\n1. Verify green status bar in tmux\n2. Check emoji indicators\n3. Test multiple sessions",
    "sessionId": "tmux-automation-'$(date +%s)'",
    "itermProfile": "Automation"
  }' | jq -r '.message // .error'

echo ""
echo ""
echo "✅ tmux Sessions Created!"
echo ""
echo "🔍 Check your tmux sessions:"
echo "tmux list-sessions"
echo ""
echo "🎯 To attach to any session:"
echo "tmux attach-session -t <session-name>"
echo ""
echo "💡 Benefits you should see:"
echo "• 🎨 Color-coded status bars (blue, purple, green)"
echo "• 📱 Emoji indicators in window names"  
echo "• 💾 Sessions persist even if terminal closes"
echo "• 🔄 Can detach (Ctrl+B, D) and reattach anytime"
echo "• 📚 Full scroll history preserved"
echo "• ⚡ No more profile issues - everything works!"
echo ""
echo "🚀 This is much better than iTerm profiles!"