#!/bin/bash

# Claude Docker Conversation Backup System
# Automatically backs up all Docker conversations to Mac filesystem
set -euo pipefail

# Configuration
BACKUP_DIR="$HOME/.claude-docker-conversations"
CLAUDE_CONFIG_VOLUME="claude-code-config"
CLEANUP_DAYS=30

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN:${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"; }

# Create backup directory structure
setup_backup_directory() {
    log "Setting up backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"/{conversations,metadata,exports}
    
    # Create backup info file
    cat > "$BACKUP_DIR/README.md" << 'EOF'
# Claude Docker Conversations Backup

This directory contains automated backups of all Claude Code conversations from Docker containers.

## Structure

- `conversations/` - Raw JSONL conversation files
- `metadata/` - Container and session metadata
- `exports/` - Human-readable exports and summaries

## Files

- Each conversation is saved as `{session-id}.jsonl`
- Metadata includes container info, timestamps, and project details
- Exports provide readable summaries of conversation content

## Auto-cleanup

Conversations older than 30 days are automatically archived to reduce storage usage.
EOF
}

# Backup all conversations from Docker volume
backup_conversations() {
    log "🔄 Starting conversation backup..."
    
    if ! docker volume inspect "$CLAUDE_CONFIG_VOLUME" >/dev/null 2>&1; then
        warn "Claude config volume not found: $CLAUDE_CONFIG_VOLUME"
        return 1
    fi
    
    local backup_timestamp=$(date +%Y%m%d-%H%M%S)
    local session_count=0
    
    # Create temporary container to access volume
    docker run --rm \
        -v "$CLAUDE_CONFIG_VOLUME:/config:ro" \
        -v "$BACKUP_DIR:/backup" \
        alpine sh -c '
        cd /config/projects/-workspace
        for jsonl_file in *.jsonl; do
            if [ -f "$jsonl_file" ]; then
                # Extract session ID from filename
                session_id="${jsonl_file%.jsonl}"
                echo "📁 Backing up: $session_id"
                
                # Copy conversation file
                cp "$jsonl_file" "/backup/conversations/${session_id}.jsonl"
                
                # Create metadata file
                first_line=$(head -1 "$jsonl_file" 2>/dev/null || echo "{}")
                last_line=$(tail -1 "$jsonl_file" 2>/dev/null || echo "{}")
                
                cat > "/backup/metadata/${session_id}_metadata.json" << EOF_METADATA
{
    "session_id": "$session_id",
    "backup_timestamp": "$backup_timestamp",
    "file_size": $(stat -c%s "$jsonl_file" 2>/dev/null || echo 0),
    "line_count": $(wc -l < "$jsonl_file" 2>/dev/null || echo 0),
    "first_message_timestamp": "$(echo "$first_line" | grep -o "timestamp.*[0-9]" | head -1 || echo "unknown")",
    "last_message_timestamp": "$(echo "$last_line" | grep -o "timestamp.*[0-9]" | head -1 || echo "unknown")",
    "backup_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF_METADATA
                
                # Create human-readable export
                echo "# Conversation Export: $session_id" > "/backup/exports/${session_id}_summary.md"
                echo "**Backup Date:** $(date)" >> "/backup/exports/${session_id}_summary.md"
                echo "**Session ID:** $session_id" >> "/backup/exports/${session_id}_summary.md"
                echo "" >> "/backup/exports/${session_id}_summary.md"
                
                # Extract key conversation details (first few messages for context)
                echo "## Conversation Start" >> "/backup/exports/${session_id}_summary.md"
                head -5 "$jsonl_file" | while IFS= read -r line; do
                    # Extract user messages and assistant responses safely
                    if echo "$line" | grep -q "\"role\":\"user\""; then
                        echo "**User:** [Message content available in JSONL file]" >> "/backup/exports/${session_id}_summary.md"
                    elif echo "$line" | grep -q "\"role\":\"assistant\""; then
                        echo "**Assistant:** [Response content available in JSONL file]" >> "/backup/exports/${session_id}_summary.md"
                    fi
                done 2>/dev/null || true
                
                echo "" >> "/backup/exports/${session_id}_summary.md"
                echo "## File Details" >> "/backup/exports/${session_id}_summary.md"
                echo "- **File:** conversations/${session_id}.jsonl" >> "/backup/exports/${session_id}_summary.md"
                echo "- **Size:** $(stat -c%s "$jsonl_file" 2>/dev/null || echo 0) bytes" >> "/backup/exports/${session_id}_summary.md"
                echo "- **Messages:** $(wc -l < "$jsonl_file" 2>/dev/null || echo 0) entries" >> "/backup/exports/${session_id}_summary.md"
            fi
        done
        
        # Count sessions
        ls -1 *.jsonl 2>/dev/null | wc -l > /backup/session_count.tmp || echo 0 > /backup/session_count.tmp
    '
    
    session_count=$(cat "$BACKUP_DIR/session_count.tmp" 2>/dev/null || echo 0)
    rm -f "$BACKUP_DIR/session_count.tmp"
    
    log "✅ Backup completed: $session_count conversations saved"
    log "📁 Backup location: $BACKUP_DIR"
}

# Clean up old backups
cleanup_old_backups() {
    log "🧹 Cleaning up backups older than $CLEANUP_DAYS days..."
    
    local cleaned=0
    
    # Find and remove old files
    for dir in conversations metadata exports; do
        if [ -d "$BACKUP_DIR/$dir" ]; then
            find "$BACKUP_DIR/$dir" -type f -mtime +$CLEANUP_DAYS -delete && {
                cleaned=$((cleaned + 1))
            } || true
        fi
    done
    
    if [ $cleaned -gt 0 ]; then
        log "🗑️  Cleaned up $cleaned old backup files"
    else
        log "✨ No old backups to clean up"
    fi
}

# Show backup status
show_status() {
    log "📊 Claude Docker Conversation Backup Status"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        warn "Backup directory not found. Run with 'backup' command first."
        return 1
    fi
    
    local conv_count=$(ls -1 "$BACKUP_DIR/conversations"/*.jsonl 2>/dev/null | wc -l || echo 0)
    local total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")
    
    echo -e "${BLUE}📁 Backup Directory:${NC} $BACKUP_DIR"
    echo -e "${BLUE}💬 Conversations:${NC} $conv_count"
    echo -e "${BLUE}💾 Total Size:${NC} $total_size"
    echo ""
    
    if [ $conv_count -gt 0 ]; then
        echo -e "${BLUE}📋 Recent Conversations:${NC}"
        ls -lt "$BACKUP_DIR/conversations"/*.jsonl 2>/dev/null | head -5 | while read -r line; do
            filename=$(echo "$line" | awk '{print $NF}')
            session_id=$(basename "$filename" .jsonl)
            timestamp=$(echo "$line" | awk '{print $6, $7, $8}')
            echo "  • $session_id ($timestamp)"
        done || true
    fi
    
    echo ""
}

# Restore conversation to current Claude session
restore_conversation() {
    local session_id="$1"
    local conv_file="$BACKUP_DIR/conversations/${session_id}.jsonl"
    
    if [ ! -f "$conv_file" ]; then
        error "Conversation not found: $session_id"
        return 1
    fi
    
    log "🔄 Restoring conversation: $session_id"
    
    # Copy back to Docker volume
    docker run --rm \
        -v "$CLAUDE_CONFIG_VOLUME:/config" \
        -v "$conv_file:/restore_file.jsonl:ro" \
        alpine sh -c "cp /restore_file.jsonl /config/projects/-workspace/${session_id}.jsonl"
    
    log "✅ Conversation restored to Docker volume"
    log "💡 You can now reference this conversation in your Claude session"
}

# Main function
main() {
    case "${1:-backup}" in
        "backup")
            setup_backup_directory
            backup_conversations
            cleanup_old_backups
            show_status
            ;;
        "status")
            show_status
            ;;
        "restore")
            if [ -z "${2:-}" ]; then
                error "Usage: $0 restore <session-id>"
                exit 1
            fi
            restore_conversation "$2"
            ;;
        "cleanup")
            cleanup_old_backups
            ;;
        "help"|"-h"|"--help")
            cat << 'EOF'
Claude Docker Conversation Backup System

USAGE:
    ./conversation-backup.sh [command]

COMMANDS:
    backup          Backup all conversations from Docker (default)
    status          Show backup status and recent conversations
    restore <id>    Restore a specific conversation to Docker
    cleanup         Clean up old backup files
    help            Show this help

EXAMPLES:
    ./conversation-backup.sh                    # Backup all conversations
    ./conversation-backup.sh status             # Show backup status
    ./conversation-backup.sh restore abc123     # Restore conversation abc123

BACKUP LOCATION:
    All conversations are saved to: ~/.claude-docker-conversations/
EOF
            ;;
        *)
            error "Unknown command: $1"
            echo "Use 'help' for usage information."
            exit 1
            ;;
    esac
}

# Run main function
main "$@"