#!/bin/bash

# Docker Session Backup Script
# Saves all running Claude sessions before Docker restart

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/Users/abhishek/Work/claude-sessions-backup-$TIMESTAMP"

echo "🔄 Docker Session Backup Started: $TIMESTAMP"
echo "📁 Backup Directory: $BACKUP_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Key sessions to prioritize
PRIORITY_SESSIONS=(
    "claude-session-palladio-software-25-20250609-174822"  # Medusa/Salesforce sync
    "claude-session-aralco-salesforce-migration-20250609-174859"  # Aralco migration
)

echo ""
echo "🎯 Backing up PRIORITY sessions first..."

for session in "${PRIORITY_SESSIONS[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "^${session}$"; then
        echo ""
        echo "💾 Backing up: $session"
        
        # Create session directory
        SESSION_DIR="$BACKUP_DIR/$session"
        mkdir -p "$SESSION_DIR"
        
        # Export container as tar
        echo "  📦 Exporting container..."
        docker export "$session" > "$SESSION_DIR/container.tar"
        
        # Save container metadata
        echo "  📋 Saving metadata..."
        docker inspect "$session" > "$SESSION_DIR/inspect.json"
        
        # Copy important workspace files
        echo "  📂 Copying workspace files..."
        docker cp "$session:/workspace" "$SESSION_DIR/" 2>/dev/null || echo "    ⚠️  No /workspace found"
        docker cp "$session:/home/claude" "$SESSION_DIR/" 2>/dev/null || echo "    ⚠️  No /home/claude found"
        
        # Save current working directory and git state
        echo "  🌿 Saving git state..."
        docker exec "$session" /bin/bash -c "pwd; git status; git branch; git log --oneline -5" > "$SESSION_DIR/git-state.txt" 2>/dev/null || echo "    ⚠️  No git found"
        
        echo "  ✅ $session backed up successfully"
    else
        echo "  ⚠️  Session $session not found"
    fi
done

echo ""
echo "📊 Backing up ALL other Claude sessions..."

# Get all Claude sessions
ALL_SESSIONS=$(docker ps --format "{{.Names}}" | grep "^claude-session-")

for session in $ALL_SESSIONS; do
    # Skip if already backed up
    if [[ " ${PRIORITY_SESSIONS[@]} " =~ " ${session} " ]]; then
        continue
    fi
    
    echo "💾 Quick backup: $session"
    SESSION_DIR="$BACKUP_DIR/$session"
    mkdir -p "$SESSION_DIR"
    
    # Just save metadata and key files (faster)
    docker inspect "$session" > "$SESSION_DIR/inspect.json"
    docker exec "$session" /bin/bash -c "pwd; ls -la" > "$SESSION_DIR/status.txt" 2>/dev/null || echo "No status"
done

echo ""
echo "📋 Creating restoration script..."

cat > "$BACKUP_DIR/restore-sessions.sh" << 'RESTORE_SCRIPT'
#!/bin/bash

echo "🔄 Docker Session Restoration Script"
echo "This script helps restore sessions after Docker restart"
echo ""

BACKUP_DIR="$(dirname "$0")"
echo "📁 Backup Directory: $BACKUP_DIR"

echo "🎯 Priority Sessions Available:"
for dir in "$BACKUP_DIR"/claude-session-*; do
    if [[ -d "$dir" && -f "$dir/container.tar" ]]; then
        session_name=$(basename "$dir")
        echo "  📦 $session_name"
    fi
done

echo ""
echo "💡 To restore a specific session:"
echo "1. docker import [backup_dir]/[session_name]/container.tar [session_name]:restored"
echo "2. docker run -it --name [session_name]-restored [session_name]:restored /bin/bash"
echo "3. Copy workspace files back if needed"

echo ""
echo "🚀 For priority sessions, use individual restore scripts in each directory"
RESTORE_SCRIPT

chmod +x "$BACKUP_DIR/restore-sessions.sh"

# Create individual restore scripts for priority sessions
for session in "${PRIORITY_SESSIONS[@]}"; do
    if [[ -d "$BACKUP_DIR/$session" ]]; then
        cat > "$BACKUP_DIR/$session/restore-this-session.sh" << EOF
#!/bin/bash

echo "🔄 Restoring session: $session"
BACKUP_DIR="\$(dirname "\$0")"

echo "📦 Importing container..."
docker import "\$BACKUP_DIR/container.tar" "$session:restored"

echo "🚀 Starting restored container..."
docker run -it -d --name "$session-restored" "$session:restored" /bin/bash

echo "📂 Copying workspace back..."
if [[ -d "\$BACKUP_DIR/workspace" ]]; then
    docker cp "\$BACKUP_DIR/workspace" "$session-restored:/workspace"
fi

if [[ -d "\$BACKUP_DIR/claude" ]]; then
    docker cp "\$BACKUP_DIR/claude" "$session-restored:/home/claude"
fi

echo "✅ Session restored as: $session-restored"
echo "🔗 Connect with: docker exec -it $session-restored /bin/bash"
EOF
        chmod +x "$BACKUP_DIR/$session/restore-this-session.sh"
    fi
done

echo ""
echo "✅ BACKUP COMPLETE!"
echo ""
echo "📋 BACKUP SUMMARY:"
echo "📁 Location: $BACKUP_DIR"
echo "🎯 Priority sessions backed up with full data"
echo "📊 All other sessions backed up with metadata"
echo ""
echo "🔄 NEXT STEPS:"
echo "1. ✅ Backup complete - safe to restart Docker"
echo "2. 🔧 Go to Docker Desktop → Settings → Resources"
echo "3. 📈 Increase Memory to 16GB+"
echo "4. 🔄 Restart Docker Desktop"
echo "5. 🚀 Run: $BACKUP_DIR/restore-sessions.sh"
echo ""
echo "🎯 To restore Medusa/Salesforce session specifically:"
echo "   Run: $BACKUP_DIR/claude-session-palladio-software-25-20250609-174822/restore-this-session.sh"