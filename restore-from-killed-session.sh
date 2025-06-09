#!/bin/bash

echo "🔄 Restoring Killed Claude Session..."
echo "Session: claude-session-palladio-software-25-20250609-174822"
echo "Last known position: Working on Salesforce field deployment verification"
echo ""

# Open Terminal and reconnect to Docker session
osascript << 'EOF'
tell application "Terminal"
    activate
    set newTab to do script "
echo '🚨 Claude Session Restoration'
echo 'Session was killed during Salesforce field verification'
echo ''
echo '📍 LAST KNOWN POSITION:'
echo '• Claude was testing field deployment issues'
echo '• Found that fields exist but not accessible via API'
echo '• Was about to create verification script'
echo '• Session was exploring for 135s with 1.3k tokens'
echo ''

# Connect to Docker session
docker exec -it claude-session-palladio-software-25-20250609-174822 /bin/bash -c '
echo \"📁 Current Status Check:\"
pwd
echo \"\"
echo \"🌿 Git Status:\"
git status --short
echo \"\"
echo \"📊 Last Git Commits:\"
git log --oneline -3
echo \"\"
echo \"✅ Available Test Scripts:\"
ls -la *.js | grep test
echo \"\"
echo \"🔍 Last Progress Update:\"
tail -10 PROGRESS.md
echo \"\"
echo \"🚀 Restarting Claude Code...\"
echo \"\"

# Restart Claude Code
claude code --dangerously-skip-permissions
'
"
    set custom title of newTab to "🚨 Restored: Medusa/Salesforce Session"
end tell
EOF

echo ""
echo "✅ Restoration script executed!"
echo ""
echo "📋 EXACT RESTORATION CONTEXT:"
echo "============================================="
echo ""
echo "🎯 WHERE CLAUDE LEFT OFF:"
echo "• Was investigating Salesforce field deployment issues"
echo "• Fields exist in Salesforce but not accessible via API"
echo "• Was reading deploy-salesforce-fields-fixed.js"
echo "• About to create field verification script"
echo "• Status: 'Exploring... (135s · 1.3k tokens)'"
echo ""
echo "🔧 CURRENT ISSUE BEING SOLVED:"
echo "• Fields created as 'Product2.Field__c' but API can't access them"
echo "• Need to verify field deployment and API accessibility"
echo "• May need different deployment approach"
echo ""
echo "💬 WHAT TO TELL CLAUDE:"
echo "\"Continue investigating the Salesforce field accessibility issue."
echo "You were checking why fields exist but aren't accessible via API."
echo "You were about to create a verification script to test field"
echo "deployment. The last test showed fields exist but API can't reach them.\""
echo ""
echo "📁 KEY FILES TO REFERENCE:"
echo "• deploy-salesforce-fields-fixed.js"
echo "• test-enhanced-sync-final.js" 
echo "• PROGRESS.md"