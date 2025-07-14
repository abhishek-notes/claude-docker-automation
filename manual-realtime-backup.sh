#!/bin/bash

# Manual Real-Time Backup for Current Session
# Run this periodically while working to backup your current conversation

set -euo pipefail

CLAUDE_CONFIG_VOLUME="claude-code-config"
BACKUP_DIR="$HOME/.claude-docker-conversations"
REALTIME_DIR="$BACKUP_DIR/realtime"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }

# Create directories
mkdir -p "$REALTIME_DIR"

# Check Docker
if ! docker ps >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker not running${NC}"
    exit 1
fi

# Check volume
if ! docker volume inspect "$CLAUDE_CONFIG_VOLUME" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Claude config volume not found${NC}"
    exit 1
fi

log "💾 Backing up current conversations..."

# Get the 3 most recent conversations and backup to realtime
backup_count=0
docker run --rm \
    -v "$CLAUDE_CONFIG_VOLUME:/config:ro" \
    -v "$REALTIME_DIR:/realtime" \
    alpine sh -c '
    cd /config/projects/-workspace 2>/dev/null || exit 0
    echo "Recent conversations:"
    ls -t *.jsonl 2>/dev/null | head -3 | while read jsonl_file; do
        if [ -f "$jsonl_file" ]; then
            session_id="${jsonl_file%.jsonl}"
            echo "  Backing up: $session_id"
            cp "$jsonl_file" "/realtime/$jsonl_file" 2>/dev/null || echo "  Failed: $session_id"
        fi
    done
' && {
    backup_count=$(ls "$REALTIME_DIR"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
    log "✅ Real-time backup completed: $backup_count conversations"
} || {
    echo -e "${YELLOW}⚠️  Backup failed${NC}"
    exit 1
}

# Show current status
echo ""
echo -e "${BLUE}📊 Real-Time Backup Status:${NC}"
echo -e "${BLUE}📁 Location:${NC} $REALTIME_DIR"
echo -e "${BLUE}💾 Files:${NC} $backup_count conversations"

if [ "$backup_count" -gt 0 ]; then
    echo -e "${BLUE}📋 Recent backups:${NC}"
    ls -lt "$REALTIME_DIR"/*.jsonl 2>/dev/null | head -3 | while read -r line; do
        filename=$(basename "$(echo "$line" | awk '{print $NF}')" .jsonl)
        timestamp=$(echo "$line" | awk '{print $6, $7, $8}')
        size=$(echo "$line" | awk '{print $5}')
        echo "  • $filename ($timestamp, $size bytes)"
    done
fi

echo ""
echo -e "${GREEN}💡 TIP:${NC} Run this script periodically while working to keep real-time backups current"
echo -e "${GREEN}💡 ALIAS:${NC} Add 'alias backup-now=\"$0\"' to your shell profile for quick access"