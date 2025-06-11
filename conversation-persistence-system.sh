#!/bin/bash

# Claude Conversation Persistence System
# Ensures all conversations are continuously backed up to host filesystem

set -e

# Configuration
BACKUP_BASE_DIR="/Users/abhishek/Work/claude-conversations-backup"
CONVERSATION_EXPORT_DIR="/Users/abhishek/Work/claude-conversations-exports"
CLAUDE_VOLUMES_DIR="/var/lib/docker/volumes"
SYNC_INTERVAL=300  # 5 minutes

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN:${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"; }

# Ensure directories exist
setup_directories() {
    log "Setting up conversation persistence directories..."
    
    mkdir -p "$BACKUP_BASE_DIR"
    mkdir -p "$CONVERSATION_EXPORT_DIR"
    mkdir -p "$BACKUP_BASE_DIR/raw-volumes"
    mkdir -p "$BACKUP_BASE_DIR/clean-conversations"
    
    log "✅ Directories created"
}

# Create conversation backup function
backup_conversations() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="$BACKUP_BASE_DIR/backup-$timestamp"
    
    log "🔄 Starting conversation backup..."
    
    # Find all Claude-related volumes
    local claude_volumes=$(docker volume ls --filter "name=claude" --format "{{.Name}}")
    
    if [ -z "$claude_volumes" ]; then
        warn "No Claude volumes found"
        return 0
    fi
    
    mkdir -p "$backup_dir"
    
    # Backup each volume
    for volume in $claude_volumes; do
        log "📦 Backing up volume: $volume"
        
        local volume_backup="$backup_dir/$volume"
        mkdir -p "$volume_backup"
        
        # Copy volume data using Docker
        docker run --rm \
            -v "$volume:/source:ro" \
            -v "$volume_backup:/backup" \
            alpine cp -r /source/. /backup/ 2>/dev/null || {
            warn "Failed to backup volume $volume"
            continue
        }
        
        # Extract conversations if they exist
        if [ -d "$volume_backup/projects" ]; then
            log "📝 Found conversation data in $volume"
            
            # Copy conversation files to exports
            find "$volume_backup/projects" -name "*.jsonl" -exec cp {} "$CONVERSATION_EXPORT_DIR/" \; 2>/dev/null || true
        fi
    done
    
    log "✅ Backup completed: $backup_dir"
    echo "$backup_dir"
}

# Real-time conversation monitoring
start_conversation_monitor() {
    log "🔍 Starting real-time conversation monitor..."
    
    while true; do
        # Check for active Claude containers
        local containers=$(docker ps --filter "name=claude" --format "{{.Names}}")
        
        if [ -n "$containers" ]; then
            for container in $containers; do
                log "🔄 Syncing conversations from $container..."
                
                # Create container-specific backup
                local container_backup="$BACKUP_BASE_DIR/live-sync/$container"
                mkdir -p "$container_backup"
                
                # Sync Claude config and conversations
                docker cp "$container:/home/claude/.claude" "$container_backup/" 2>/dev/null || true
                
                # Export any new conversations
                if [ -d "$container_backup/.claude/projects" ]; then
                    find "$container_backup/.claude/projects" -name "*.jsonl" -newer "$CONVERSATION_EXPORT_DIR/.last_sync" -exec cp {} "$CONVERSATION_EXPORT_DIR/" \; 2>/dev/null || true
                fi
            done
        fi
        
        # Update sync timestamp
        touch "$CONVERSATION_EXPORT_DIR/.last_sync"
        
        # Wait for next sync
        sleep $SYNC_INTERVAL
    done
}

# Export conversations to clean format
export_clean_conversations() {
    log "📄 Exporting conversations to clean format..."
    
    local export_timestamp=$(date +%Y%m%d-%H%M%S)
    local clean_export_dir="$CONVERSATION_EXPORT_DIR/clean-$export_timestamp"
    
    mkdir -p "$clean_export_dir"
    
    # Use our existing parser
    if [ -f "/Users/abhishek/Work/claude-conversation-recovery-20250609-160726/parse-conversations.js" ]; then
        cd "$CONVERSATION_EXPORT_DIR"
        
        # Create a temporary projects structure
        mkdir -p projects/-workspace
        cp *.jsonl projects/-workspace/ 2>/dev/null || true
        
        # Run the parser
        node "/Users/abhishek/Work/claude-conversation-recovery-20250609-160726/parse-conversations.js"
        
        # Move clean conversations to export directory
        if [ -d "clean-conversations" ]; then
            mv clean-conversations/* "$clean_export_dir/"
            rmdir clean-conversations
        fi
        
        # Cleanup temp structure
        rm -rf projects
        
        log "✅ Clean conversations exported to: $clean_export_dir"
    else
        warn "Conversation parser not found - only raw backups available"
    fi
}

# Automatic recovery function
recover_conversations_on_startup() {
    log "🔧 Checking for conversation recovery on startup..."
    
    # Check if there are any stopped Claude containers with unsaved work
    local stopped_containers=$(docker ps -a --filter "name=claude" --filter "status=exited" --format "{{.Names}}")
    
    if [ -n "$stopped_containers" ]; then
        warn "Found stopped Claude containers with potential unsaved conversations"
        
        for container in $stopped_containers; do
            log "🔄 Attempting to recover conversations from $container..."
            
            # Try to copy data from stopped container
            local recovery_dir="$BACKUP_BASE_DIR/recovery-$(date +%Y%m%d-%H%M%S)/$container"
            mkdir -p "$recovery_dir"
            
            docker cp "$container:/home/claude/.claude" "$recovery_dir/" 2>/dev/null && {
                log "✅ Recovered data from $container"
                
                # Export conversations if found
                if [ -d "$recovery_dir/.claude/projects" ]; then
                    find "$recovery_dir/.claude/projects" -name "*.jsonl" -exec cp {} "$CONVERSATION_EXPORT_DIR/" \;
                fi
            } || warn "Could not recover data from $container"
        done
    fi
}

# Cleanup old backups (keep last 10)
cleanup_old_backups() {
    log "🧹 Cleaning up old backups..."
    
    cd "$BACKUP_BASE_DIR"
    
    # Count backup directories
    local backup_count=$(find . -maxdepth 1 -type d -name "backup-*" | wc -l)
    
    if [ "$backup_count" -gt 10 ]; then
        local to_remove=$((backup_count - 10))
        find . -maxdepth 1 -type d -name "backup-*" -print0 | \
            xargs -0 ls -dt | \
            tail -n "$to_remove" | \
            xargs rm -rf
        log "🗑️ Removed $to_remove old backups"
    fi
}

# Setup systemd service for automatic monitoring (macOS uses launchd instead)
setup_persistent_service() {
    log "⚙️ Setting up persistent conversation monitoring service..."
    
    # Create launchd plist for macOS
    local plist_file="$HOME/Library/LaunchAgents/com.claude.conversation.backup.plist"
    
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude.conversation.backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(pwd)/conversation-persistence-system.sh</string>
        <string>monitor</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$BACKUP_BASE_DIR/conversation-monitor.log</string>
    <key>StandardErrorPath</key>
    <string>$BACKUP_BASE_DIR/conversation-monitor.error.log</string>
</dict>
</plist>
EOF
    
    # Load the service
    launchctl unload "$plist_file" 2>/dev/null || true
    launchctl load "$plist_file"
    
    log "✅ Persistent monitoring service installed"
}

# Main command dispatcher
case "${1:-help}" in
    "setup")
        setup_directories
        recover_conversations_on_startup
        backup_conversations
        export_clean_conversations
        setup_persistent_service
        log "🎉 Conversation persistence system fully set up!"
        ;;
        
    "backup")
        setup_directories
        backup_dir=$(backup_conversations)
        export_clean_conversations
        cleanup_old_backups
        log "💾 Manual backup completed: $backup_dir"
        ;;
        
    "monitor")
        setup_directories
        start_conversation_monitor
        ;;
        
    "export")
        export_clean_conversations
        ;;
        
    "recover")
        recover_conversations_on_startup
        export_clean_conversations
        ;;
        
    "status")
        echo -e "${BLUE}=== Conversation Persistence Status ===${NC}"
        echo "Backup directory: $BACKUP_BASE_DIR"
        echo "Export directory: $CONVERSATION_EXPORT_DIR"
        echo ""
        echo "Recent backups:"
        ls -lt "$BACKUP_BASE_DIR" | grep "backup-" | head -5
        echo ""
        echo "Active Claude containers:"
        docker ps --filter "name=claude" --format "table {{.Names}}\t{{.Status}}"
        echo ""
        echo "Claude volumes:"
        docker volume ls --filter "name=claude"
        ;;
        
    "help"|*)
        cat << 'EOF'
Claude Conversation Persistence System

USAGE:
    ./conversation-persistence-system.sh <command>

COMMANDS:
    setup     - Initialize the complete persistence system
    backup    - Perform manual backup of all conversations
    monitor   - Start real-time conversation monitoring
    export    - Export conversations to clean format
    recover   - Recover conversations from stopped containers
    status    - Show system status
    help      - Show this help

FEATURES:
    • Automatic conversation backup every 5 minutes
    • Real-time monitoring of active Claude containers
    • Clean conversation export in readable format
    • Crash recovery from stopped containers
    • Persistent service that survives reboots
    • Automatic cleanup of old backups

DIRECTORIES:
    Backups: /Users/abhishek/Work/claude-conversations-backup
    Exports: /Users/abhishek/Work/claude-conversations-exports

The system will automatically monitor and backup all Claude conversations,
ensuring you never lose conversation history again.
EOF
        ;;
esac