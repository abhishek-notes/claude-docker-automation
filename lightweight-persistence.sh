#!/bin/bash

# Lightweight Claude Conversation Persistence
# Fast, minimal backup system for conversations only

set -e

# Configuration - much more targeted
CONVERSATION_BACKUP_DIR="/Users/abhishek/Work/claude-conversations-exports"
CLAUDE_CONFIG_VOLUME="claude-code-config"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }

# Fast conversation backup - only backup conversation files
quick_conversation_backup() {
    # Only create directory if it doesn't exist
    [ ! -d "$CONVERSATION_BACKUP_DIR" ] && mkdir -p "$CONVERSATION_BACKUP_DIR"
    
    # Only backup from claude-code-config volume (where conversations are stored)
    if docker volume ls --format "{{.Name}}" | grep -q "^${CLAUDE_CONFIG_VOLUME}$"; then
        # Quick extraction of just conversation files
        docker run --rm \
            -v "$CLAUDE_CONFIG_VOLUME:/source:ro" \
            -v "$CONVERSATION_BACKUP_DIR:/backup" \
            alpine sh -c "
                if [ -d /source/projects ]; then
                    find /source/projects -name '*.jsonl' -exec cp {} /backup/ \; 2>/dev/null || true
                fi
            " >/dev/null 2>&1 &
    fi
}

# Start lightweight monitoring (every 10 minutes, not 5)
start_lightweight_monitor() {
    while true; do
        quick_conversation_backup
        sleep 600  # 10 minutes
    done &
}

# Clean up old conversation files (keep last 50)
cleanup_old_conversations() {
    if [ -d "$CONVERSATION_BACKUP_DIR" ]; then
        cd "$CONVERSATION_BACKUP_DIR"
        # Only keep the 50 most recent .jsonl files
        ls -t *.jsonl 2>/dev/null | tail -n +51 | xargs rm -f 2>/dev/null || true
    fi
}

# Main command
case "${1:-quick-backup}" in
    "quick-backup")
        quick_conversation_backup
        ;;
        
    "start-monitor")
        start_lightweight_monitor
        ;;
        
    "cleanup")
        cleanup_old_conversations
        ;;
        
    *)
        # Just do a quick backup by default
        quick_conversation_backup
        ;;
esac