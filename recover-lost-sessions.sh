#!/bin/bash

# Claude Session Recovery Tool
# Recovers conversations and restarts containers that were lost in crashes

set -e

AUTOMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECOVERY_BASE="/Users/abhishek/Work/claude-conversations-backup"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN:${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"; }

# Check what containers were lost
analyze_lost_containers() {
    log "🔍 Analyzing lost Claude containers..."
    
    echo -e "${BLUE}=== Container Status ===${NC}"
    echo "Currently running:"
    docker ps --filter "name=claude" --format "table {{.Names}}\t{{.Status}}" || echo "None"
    
    echo ""
    echo "Stopped/crashed containers:"
    docker ps -a --filter "name=claude" --filter "status=exited" --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}"
    
    echo ""
    echo "Available Docker volumes:"
    docker volume ls --filter "name=claude"
}

# Recover conversations from stopped containers
recover_conversations() {
    log "💾 Recovering conversations from stopped containers..."
    
    local stopped_containers=$(docker ps -a --filter "name=claude" --filter "status=exited" --format "{{.Names}}")
    
    if [ -z "$stopped_containers" ]; then
        log "ℹ️ No stopped containers found"
        return 0
    fi
    
    local recovery_dir="$RECOVERY_BASE/crash-recovery-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$recovery_dir"
    
    for container in $stopped_containers; do
        log "🔄 Recovering from: $container"
        
        local container_recovery="$recovery_dir/$container"
        mkdir -p "$container_recovery"
        
        # Try to copy conversation data
        if docker cp "$container:/home/claude/.claude" "$container_recovery/" 2>/dev/null; then
            log "✅ Recovered data from $container"
            
            # Check for conversation files
            local conversation_count=$(find "$container_recovery/.claude" -name "*.jsonl" 2>/dev/null | wc -l)
            if [ "$conversation_count" -gt 0 ]; then
                log "📝 Found $conversation_count conversation files"
                
                # Copy to main exports directory
                find "$container_recovery/.claude" -name "*.jsonl" -exec cp {} "/Users/abhishek/Work/claude-conversations-exports/" \; 2>/dev/null || true
            fi
        else
            warn "Could not recover data from $container"
        fi
    done
    
    log "💾 Recovery completed in: $recovery_dir"
}

# Restart lost sessions
restart_lost_sessions() {
    log "🔄 Analyzing which sessions to restart..."
    
    # Get list of project directories that had active sessions
    local project_dirs=()
    
    # Check backup data for recent activity
    if [ -d "$RECOVERY_BASE" ]; then
        local recent_backups=$(find "$RECOVERY_BASE" -name "backup-*" -type d -mtime -1 | head -3)
        
        for backup in $recent_backups; do
            # Look for different project patterns in volume names
            local volumes=$(find "$backup" -name "claude-*" -type d)
            
            for volume_dir in $volumes; do
                local volume_name=$(basename "$volume_dir")
                
                # Extract project info from volume name patterns
                case "$volume_name" in
                    *palladio*)
                        project_dirs+=("/Users/abhishek/Work/palladio-software-25")
                        ;;
                    *automation*)
                        project_dirs+=("/Users/abhishek/Work/claude-automation")
                        ;;
                    *Work*)
                        project_dirs+=("/Users/abhishek/Work")
                        ;;
                esac
            done
        done
    fi
    
    # Remove duplicates
    local unique_projects=($(printf '%s\n' "${project_dirs[@]}" | sort -u))
    
    if [ ${#unique_projects[@]} -eq 0 ]; then
        log "ℹ️ No recent project activity detected"
        
        # Offer manual restart options
        echo -e "${YELLOW}Manual restart options:${NC}"
        echo "1. ./claude-session-wrapper.sh ./claude-direct-task.sh /Users/abhishek/Work"
        echo "2. ./claude-session-wrapper.sh ./claude-direct-task.sh /Users/abhishek/Work/palladio-software-25"
        echo "3. ./start-system.sh  # For web interface"
        return 0
    fi
    
    echo -e "${BLUE}=== Detected Recent Project Activity ===${NC}"
    for i in "${!unique_projects[@]}"; do
        echo "$((i+1)). ${unique_projects[i]}"
    done
    
    echo ""
    read -p "Which projects would you like to restart? (Enter numbers separated by spaces, or 'all'): " selection
    
    if [ "$selection" = "all" ]; then
        for project in "${unique_projects[@]}"; do
            restart_project_session "$project"
        done
    else
        for num in $selection; do
            if [ "$num" -ge 1 ] && [ "$num" -le "${#unique_projects[@]}" ]; then
                local project="${unique_projects[$((num-1))]}"
                restart_project_session "$project"
            fi
        done
    fi
}

# Restart a specific project session
restart_project_session() {
    local project_path="$1"
    
    log "🚀 Restarting session for: $project_path"
    
    if [ ! -d "$project_path" ]; then
        error "Project directory does not exist: $project_path"
        return 1
    fi
    
    # Check if there's a task file
    if [ -f "$project_path/CLAUDE_TASKS.md" ]; then
        log "📋 Found existing CLAUDE_TASKS.md - resuming task"
        
        # Use the automation system
        osascript << EOF
tell application "Terminal"
    activate
    do script "cd '$AUTOMATION_DIR' && ./claude-session-wrapper.sh ./claude-direct-task.sh '$project_path'"
end tell
EOF
    else
        log "📋 No task file found - starting interactive session"
        
        # Start interactive session
        osascript << EOF
tell application "Terminal"
    activate
    do script "cd '$AUTOMATION_DIR' && ./claude-session-wrapper.sh ./claude-direct-task.sh '$project_path'"
end tell
EOF
    fi
    
    log "✅ Session started for $project_path"
}

# Clean up crashed containers
cleanup_crashed_containers() {
    log "🧹 Cleaning up crashed containers..."
    
    # Remove crashed containers
    local crashed_containers=$(docker ps -a --filter "name=claude" --filter "status=exited" --format "{{.Names}}")
    
    if [ -n "$crashed_containers" ]; then
        echo "$crashed_containers" | xargs docker rm
        log "🗑️ Removed crashed containers"
    else
        log "ℹ️ No crashed containers to clean up"
    fi
}

# Full recovery process
full_recovery() {
    log "🔧 Starting full Claude session recovery..."
    
    # Initialize persistence system
    "$AUTOMATION_DIR/conversation-persistence-system.sh" setup
    
    # Recover conversations
    recover_conversations
    
    # Export clean conversations
    "$AUTOMATION_DIR/conversation-persistence-system.sh" export
    
    # Show analysis
    analyze_lost_containers
    
    # Restart sessions
    restart_lost_sessions
    
    # Clean up
    cleanup_crashed_containers
    
    log "🎉 Recovery process completed!"
    
    # Show final status
    echo ""
    echo -e "${BLUE}=== Recovery Summary ===${NC}"
    echo "Conversations backed up to: $RECOVERY_BASE"
    echo "Clean exports available in: /Users/abhishek/Work/claude-conversations-exports"
    echo ""
    echo "Active containers:"
    docker ps --filter "name=claude" --format "table {{.Names}}\t{{.Status}}" || echo "None currently running"
}

# Main command dispatcher
case "${1:-help}" in
    "analyze")
        analyze_lost_containers
        ;;
        
    "recover-conversations")
        recover_conversations
        ;;
        
    "restart-sessions")
        restart_lost_sessions
        ;;
        
    "cleanup")
        cleanup_crashed_containers
        ;;
        
    "full"|"all")
        full_recovery
        ;;
        
    "help"|*)
        cat << 'EOF'
Claude Session Recovery Tool

USAGE:
    ./recover-lost-sessions.sh <command>

COMMANDS:
    analyze              - Show status of lost/crashed containers
    recover-conversations - Recover conversations from stopped containers
    restart-sessions     - Restart sessions for recent projects
    cleanup             - Remove crashed containers
    full                - Complete recovery process (recommended)
    help                - Show this help

RECOVERY PROCESS:
    1. Recovers all conversation data from stopped containers
    2. Exports conversations to clean, readable format
    3. Analyzes recent project activity
    4. Offers to restart sessions for active projects
    5. Cleans up crashed containers

Use 'full' for complete recovery after a Docker crash.
EOF
        ;;
esac