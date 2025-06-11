#!/bin/bash

# Quick backup for Medusa/Salesforce session only
SESSION="claude-session-palladio-software-25-20250609-174822"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/Users/abhishek/Work/medusa-session-backup-$TIMESTAMP"

echo "🎯 Quick Backup: Medusa/Salesforce Session"
echo "📦 Session: $SESSION"
echo "📁 Backup: $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"

echo ""
echo "1️⃣ Saving workspace files..."
docker cp "$SESSION:/workspace" "$BACKUP_DIR/" 2>/dev/null && echo "   ✅ Workspace saved" || echo "   ⚠️ No workspace"

echo "2️⃣ Saving git state..."
docker exec "$SESSION" /bin/bash -c "cd /workspace && pwd && git status && git branch && git log --oneline -5 && echo '=== Files ===' && ls -la *.js" > "$BACKUP_DIR/git-state.txt" 2>/dev/null && echo "   ✅ Git state saved" || echo "   ⚠️ No git"

echo "3️⃣ Saving container metadata..."
docker inspect "$SESSION" > "$BACKUP_DIR/inspect.json" && echo "   ✅ Metadata saved"

echo "4️⃣ Saving current session info..."
cat > "$BACKUP_DIR/session-info.txt" << EOF
SESSION: $SESSION
BACKUP_TIME: $TIMESTAMP
PROJECT: Medusa to Salesforce Product Sync
GIT_BRANCH: claude/session-20250608-191408

CONTEXT:
- Working on Salesforce field accessibility issue
- Fields exist but not accessible via API  
- About to create field verification script
- Last commit: c4b8d32 - Implement comprehensive Medusa to Salesforce product sync

FILES TO RESTORE:
- deploy-salesforce-fields-fixed.js
- test-enhanced-sync-final.js
- check-medusa-fields.js
- PROGRESS.md

CLAUDE INSTRUCTION AFTER RESTORE:
"Continue investigating the Salesforce field accessibility issue. You were checking why the 27 deployed fields exist but aren't accessible via API. Create the field verification script to test deployment."
EOF

echo "5️⃣ Creating quick restore script..."
cat > "$BACKUP_DIR/quick-restore.sh" << 'RESTORE'
#!/bin/bash

echo "🔄 Quick Restore: Medusa/Salesforce Session"
BACKUP_DIR="$(dirname "$0")"

echo "📁 Backup location: $BACKUP_DIR"
echo ""
echo "🎯 TO RESTORE SESSION:"
echo "1. Start new Claude Docker session in /Users/abhishek/Work/palladio-software-25"
echo "2. Copy workspace files back:"
echo "   docker cp $BACKUP_DIR/workspace [new-session]:/workspace"
echo "3. Check git state from: $BACKUP_DIR/git-state.txt"
echo "4. Tell Claude: Continue investigating Salesforce field accessibility issue"
echo ""
echo "📋 Session Info:"
cat "$BACKUP_DIR/session-info.txt"
RESTORE

chmod +x "$BACKUP_DIR/quick-restore.sh"

echo ""
echo "✅ QUICK BACKUP COMPLETE!"
echo ""
echo "📋 SUMMARY:"
echo "📁 Backup: $BACKUP_DIR"  
echo "🎯 Session: Medusa/Salesforce sync"
echo "📂 Workspace: ✅ Backed up"
echo "🌿 Git state: ✅ Saved"
echo "📋 Metadata: ✅ Saved"
echo "🔄 Restore script: ✅ Created"
echo ""
echo "🚀 SAFE TO RESTART DOCKER NOW!"
echo ""
echo "🔄 After Docker restart with more memory:"
echo "1. Run: $BACKUP_DIR/quick-restore.sh (for instructions)"
echo "2. Or just start new session in /Users/abhishek/Work/palladio-software-25"
echo "3. Copy workspace back if needed"