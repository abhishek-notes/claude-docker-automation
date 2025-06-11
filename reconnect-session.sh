#!/bin/bash

# Script to reconnect to the halted Medusa/Salesforce sync Docker session
# This will restore the full conversation context for Claude

echo "🔄 Reconnecting to Medusa/Salesforce Sync Session..."
echo "Session: claude-session-palladio-software-25-20250609-174822"
echo ""

# Step 1: Open Terminal and connect to Docker session
echo "📋 Opening Terminal with Docker session..."
osascript << 'EOF'
tell application "Terminal"
    activate
    set newTab to do script "
echo '🎯 Claude Docker Session Restored'
echo 'Project: Medusa to Salesforce Product Sync'
echo 'Session: claude-session-palladio-software-25-20250609-174822'
echo 'Branch: claude/session-20250608-191408'
echo ''

# Connect to Docker session
docker exec -it claude-session-palladio-software-25-20250609-174822 /bin/bash -c '
echo \"📁 Project Status:\"
pwd
echo \"\"
echo \"🌿 Git Branch:\"
git branch
echo \"\"
echo \"📊 Recent Git Activity:\"
git log --oneline -5
echo \"\"
echo \"✅ Files Created This Session:\"
ls -la *.js | grep \"^-rwx\" | head -10
echo \"\"
echo \"📋 Current Progress:\"
tail -20 PROGRESS.md
echo \"\"
echo \"🚀 Starting Claude Code with conversation history...\"
echo \"\"

# Start Claude Code with bypass permissions
claude code --dangerously-skip-permissions
'
"
    set custom title of newTab to "🔄 Claude: Medusa/Salesforce Sync Session"
end tell
EOF

echo ""
echo "✅ Terminal opened with Docker session!"
echo ""
echo "📖 CONVERSATION CONTEXT TO RESTORE:"
echo "============================================"
echo ""
echo "Claude was working on implementing Medusa to Salesforce product sync."
echo ""
echo "🎯 LAST STATUS:"
echo "• Had completed all sync implementation"
echo "• Just committed the final code changes" 
echo "• Was about to write SUMMARY.md when interrupted"
echo "• Had been exploring for 1430s with 49.5k tokens used"
echo ""
echo "✅ COMPLETED TASKS:"
echo "• ✅ Analyzed project structure"
echo "• ✅ Fetched product JSON from Medusa"
echo "• ✅ Created Salesforce fields"
echo "• ✅ Deployed field changes"
echo "• ✅ Implemented product sync"
echo "• ✅ Tested sync with existing product"
echo "• ✅ Created test scripts"
echo ""
echo "⚠️  INTERRUPTED WHILE:"
echo "• Writing SUMMARY.md file"
echo "• Final documentation and cleanup"
echo ""
echo "📁 KEY FILES CREATED:"
echo "• deploy-salesforce-fields-fixed.js"
echo "• test-basic-product-sync.js" 
echo "• test-enhanced-sync-final.js"
echo "• check-medusa-fields.js"
echo "• PROGRESS.md (comprehensive)"
echo ""
echo "🔮 CONVERSATION HISTORY:"
echo "The full conversation is preserved in:"
echo "/home/claude/.claude/projects/-workspace/bd4a21f7-0b48-409e-a5b9-8a82b86237c4.jsonl"
echo ""
echo "💡 WHAT TO TELL CLAUDE:"
echo "\"Continue from where you left off. You were writing SUMMARY.md"
echo "after successfully implementing the complete Medusa to Salesforce"
echo "product sync. All implementation is done and committed. Please"
echo "finish the SUMMARY.md and provide final status.\""