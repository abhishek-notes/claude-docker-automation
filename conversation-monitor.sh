#!/bin/bash

# Claude Docker Real-Time Conversation Monitor
# Continuously monitors Docker conversations and backs them up immediately
# Protects against Mac crashes, RAM issues, and Docker failures

set -euo pipefail

# Configuration
CLAUDE_CONFIG_VOLUME="claude-code-config"
BACKUP_DIR="$HOME/.claude-docker-conversations"
REALTIME_BACKUP_DIR="$BACKUP_DIR/realtime"
MONITOR_INTERVAL=10  # seconds
MAX_MONITOR_TIME=28800  # 8 hours max monitoring
CRASH_RECOVERY_DIR="$BACKUP_DIR/crash-recovery"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN:${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"; }

# Setup monitoring directories
setup_monitoring() {
    log "🔧 Setting up real-time monitoring..."
    mkdir -p "$REALTIME_BACKUP_DIR" "$CRASH_RECOVERY_DIR"
    
    # Create monitoring state file
    cat > "$BACKUP_DIR/monitor_state.json" << EOF
{
    "monitor_pid": $$,
    "start_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "last_backup": null,
    "conversations_tracked": 0,
    "status": "starting"
}
EOF
    
    log "✅ Monitoring setup complete"
}

# Get hash of conversation file for change detection
get_file_hash() {
    local file="$1"
    if [ -f "$file" ]; then
        if command -v shasum >/dev/null 2>&1; then
            shasum -a 256 "$file" | cut -d' ' -f1
        elif command -v sha256sum >/dev/null 2>&1; then
            sha256sum "$file" | cut -d' ' -f1
        else
            # Fallback to file size and modification time
            stat -f "%z-%m" "$file" 2>/dev/null || stat -c "%s-%Y" "$file" 2>/dev/null
        fi
    else
        echo "missing"
    fi
}

# Backup single conversation with crash protection
backup_conversation_realtime() {
    local session_id="$1"
    local source_file="$2"
    local backup_timestamp=$(date +%Y%m%d-%H%M%S)
    
    # Create temporary file first (atomic operation)
    local temp_file="$REALTIME_BACKUP_DIR/${session_id}.tmp"
    local final_file="$REALTIME_BACKUP_DIR/${session_id}.jsonl"
    local crash_file="$CRASH_RECOVERY_DIR/${session_id}_${backup_timestamp}.jsonl"
    
    # Copy to temp file first
    if cp "$source_file" "$temp_file" 2>/dev/null; then
        # Verify copy integrity
        local source_size=$(stat -f "%z" "$source_file" 2>/dev/null || stat -c "%s" "$source_file" 2>/dev/null)
        local temp_size=$(stat -f "%z" "$temp_file" 2>/dev/null || stat -c "%s" "$temp_file" 2>/dev/null)
        
        if [ "$source_size" = "$temp_size" ]; then
            # Atomic move to final location
            mv "$temp_file" "$final_file"
            
            # Create crash recovery copy (with timestamp)
            cp "$final_file" "$crash_file"
            
            # Clean old crash recovery files (keep last 5)
            ls -t "$CRASH_RECOVERY_DIR/${session_id}_"*.jsonl 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
            
            log "💾 Real-time backup: $session_id (${source_size} bytes)"
            return 0
        else
            error "❌ Backup integrity check failed for $session_id"
            rm -f "$temp_file"
            return 1
        fi
    else
        error "❌ Failed to copy $session_id"
        return 1
    fi
}

# Monitor conversations in real-time
monitor_conversations() {
    log "🎯 Starting real-time conversation monitoring..."
    log "📊 Monitoring every $MONITOR_INTERVAL seconds"
    log "⏰ Max monitoring time: $((MAX_MONITOR_TIME / 3600)) hours"
    
    # Track conversation hashes
    declare -A conversation_hashes
    local start_time=$(date +%s)
    local backup_count=0
    
    # Update monitor state
    jq --arg status "monitoring" '.status = $status' "$BACKUP_DIR/monitor_state.json" > "$BACKUP_DIR/monitor_state.tmp" && mv "$BACKUP_DIR/monitor_state.tmp" "$BACKUP_DIR/monitor_state.json"
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        # Check max monitoring time
        if [ "$elapsed" -gt "$MAX_MONITOR_TIME" ]; then
            log "⏰ Max monitoring time reached, stopping..."
            break
        fi
        
        # Check if Docker is still running
        if ! docker ps >/dev/null 2>&1; then
            warn "🐳 Docker not responding, continuing to monitor existing backups..."
            sleep $MONITOR_INTERVAL
            continue
        fi
        
        # Check if volume exists
        if ! docker volume inspect "$CLAUDE_CONFIG_VOLUME" >/dev/null 2>&1; then
            warn "📦 Claude config volume not found, waiting..."
            sleep $MONITOR_INTERVAL
            continue
        fi
        
        # Monitor conversations in Docker volume
        docker run --rm \
            -v "$CLAUDE_CONFIG_VOLUME:/config:ro" \
            alpine sh -c 'cd /config/projects/-workspace 2>/dev/null && find . -name "*.jsonl" -type f 2>/dev/null | head -50' 2>/dev/null | while IFS= read -r jsonl_path; do
            
            if [ -n "$jsonl_path" ] && [ "$jsonl_path" != "." ]; then
                local filename=$(basename "$jsonl_path")
                local session_id="${filename%.jsonl}"
                
                # Get current hash via Docker
                local current_hash=$(docker run --rm \
                    -v "$CLAUDE_CONFIG_VOLUME:/config:ro" \
                    alpine sh -c "cd /config/projects/-workspace && shasum -a 256 '$filename' 2>/dev/null | cut -d' ' -f1 || stat -c '%s-%Y' '$filename' 2>/dev/null" 2>/dev/null)
                
                # Check if conversation changed
                local previous_hash="${conversation_hashes[$session_id]:-}"
                
                if [ "$current_hash" != "$previous_hash" ] && [ -n "$current_hash" ] && [ "$current_hash" != "missing" ]; then
                    # Extract and backup the conversation
                    local temp_conv_file="/tmp/claude_monitor_${session_id}.jsonl"
                    
                    if docker run --rm \
                        -v "$CLAUDE_CONFIG_VOLUME:/config:ro" \
                        -v "/tmp:/tmp" \
                        alpine sh -c "cd /config/projects/-workspace && cp '$filename' '/tmp/claude_monitor_${session_id}.jsonl'" 2>/dev/null; then
                        
                        # Backup the conversation
                        if backup_conversation_realtime "$session_id" "$temp_conv_file"; then
                            conversation_hashes[$session_id]="$current_hash"
                            backup_count=$((backup_count + 1))
                            
                            # Update state
                            jq --arg count "$backup_count" --arg time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
                                '.conversations_tracked = ($count | tonumber) | .last_backup = $time' \
                                "$BACKUP_DIR/monitor_state.json" > "$BACKUP_DIR/monitor_state.tmp" && \
                                mv "$BACKUP_DIR/monitor_state.tmp" "$BACKUP_DIR/monitor_state.json"
                        fi
                        
                        # Clean up temp file
                        rm -f "$temp_conv_file"
                    fi
                fi
            fi
        done 2>/dev/null || true
        
        # Brief status update every 10 cycles (every 100 seconds)
        if [ $((elapsed % 100)) -eq 0 ] && [ "$elapsed" -gt 0 ]; then
            log "📈 Monitoring... ${backup_count} backups, ${elapsed}s elapsed"
        fi
        
        sleep $MONITOR_INTERVAL
    done
    
    log "🛑 Real-time monitoring stopped after ${elapsed} seconds"
    log "📊 Total backups created: $backup_count"
    
    # Update final state
    jq --arg status "stopped" --arg count "$backup_count" \
        '.status = $status | .conversations_tracked = ($count | tonumber)' \
        "$BACKUP_DIR/monitor_state.json" > "$BACKUP_DIR/monitor_state.tmp" && \
        mv "$BACKUP_DIR/monitor_state.tmp" "$BACKUP_DIR/monitor_state.json"
}

# Start monitoring in background
start_background_monitor() {
    log "🚀 Starting background conversation monitor..."
    
    # Check if already running
    if [ -f "$BACKUP_DIR/monitor_state.json" ]; then
        local existing_pid=$(jq -r '.monitor_pid // empty' "$BACKUP_DIR/monitor_state.json" 2>/dev/null)
        if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
            warn "⚠️  Monitor already running with PID $existing_pid"
            return 1
        fi
    fi
    
    setup_monitoring
    
    # Start monitor in background
    nohup bash -c "$(declare -f monitor_conversations setup_monitoring backup_conversation_realtime get_file_hash log warn error); monitor_conversations" \
        > "$BACKUP_DIR/monitor.log" 2>&1 &
    
    local monitor_pid=$!
    echo $monitor_pid > "$BACKUP_DIR/monitor.pid"
    
    # Update state with PID
    jq --arg pid "$monitor_pid" '.monitor_pid = ($pid | tonumber)' \
        "$BACKUP_DIR/monitor_state.json" > "$BACKUP_DIR/monitor_state.tmp" && \
        mv "$BACKUP_DIR/monitor_state.tmp" "$BACKUP_DIR/monitor_state.json"
    
    log "✅ Background monitor started with PID: $monitor_pid"
    log "📁 Monitor log: $BACKUP_DIR/monitor.log"
    log "📊 Status file: $BACKUP_DIR/monitor_state.json"
}

# Stop background monitor
stop_background_monitor() {
    log "🛑 Stopping background monitor..."
    
    if [ -f "$BACKUP_DIR/monitor.pid" ]; then
        local monitor_pid=$(cat "$BACKUP_DIR/monitor.pid")
        if kill -0 "$monitor_pid" 2>/dev/null; then
            kill "$monitor_pid"
            log "✅ Monitor stopped (PID: $monitor_pid)"
        else
            warn "⚠️  Monitor process not found (PID: $monitor_pid)"
        fi
        rm -f "$BACKUP_DIR/monitor.pid"
    else
        warn "⚠️  No monitor PID file found"
    fi
    
    # Update state
    if [ -f "$BACKUP_DIR/monitor_state.json" ]; then
        jq '.status = "stopped"' "$BACKUP_DIR/monitor_state.json" > "$BACKUP_DIR/monitor_state.tmp" && \
            mv "$BACKUP_DIR/monitor_state.tmp" "$BACKUP_DIR/monitor_state.json"
    fi
}

# Show monitor status
show_monitor_status() {
    log "📊 Real-Time Conversation Monitor Status"
    echo ""
    
    if [ ! -f "$BACKUP_DIR/monitor_state.json" ]; then
        warn "No monitor state found. Monitor has not been started."
        return 1
    fi
    
    local state=$(cat "$BACKUP_DIR/monitor_state.json")
    local status=$(echo "$state" | jq -r '.status // "unknown"')
    local pid=$(echo "$state" | jq -r '.monitor_pid // "none"')
    local start_time=$(echo "$state" | jq -r '.start_time // "unknown"')
    local last_backup=$(echo "$state" | jq -r '.last_backup // "none"')
    local conv_count=$(echo "$state" | jq -r '.conversations_tracked // 0')
    
    echo -e "${BLUE}🎯 Monitor Status:${NC} $status"
    echo -e "${BLUE}🆔 Process ID:${NC} $pid"
    echo -e "${BLUE}⏰ Started:${NC} $start_time"
    echo -e "${BLUE}💾 Last Backup:${NC} $last_backup"
    echo -e "${BLUE}📊 Conversations Tracked:${NC} $conv_count"
    
    # Check if process is actually running
    if [ "$pid" != "none" ] && [ "$status" = "monitoring" ]; then
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}✅ Monitor is actively running${NC}"
        else
            echo -e "${RED}❌ Monitor process not found (may have crashed)${NC}"
        fi
    fi
    
    # Show recent real-time backups
    echo ""
    echo -e "${BLUE}📋 Recent Real-Time Backups:${NC}"
    if [ -d "$REALTIME_BACKUP_DIR" ]; then
        ls -lt "$REALTIME_BACKUP_DIR"/*.jsonl 2>/dev/null | head -5 | while read -r line; do
            local filename=$(echo "$line" | awk '{print $NF}')
            local session_id=$(basename "$filename" .jsonl)
            local timestamp=$(echo "$line" | awk '{print $6, $7, $8}')
            local size=$(echo "$line" | awk '{print $5}')
            echo "  • $session_id ($timestamp, $size bytes)"
        done || echo "  No real-time backups found"
    fi
    
    # Show crash recovery files
    echo ""
    echo -e "${BLUE}🛡️  Crash Recovery Files:${NC}"
    if [ -d "$CRASH_RECOVERY_DIR" ]; then
        local recovery_count=$(ls -1 "$CRASH_RECOVERY_DIR"/*.jsonl 2>/dev/null | wc -l || echo 0)
        echo "  Total recovery files: $recovery_count"
        ls -lt "$CRASH_RECOVERY_DIR"/*.jsonl 2>/dev/null | head -3 | while read -r line; do
            local filename=$(basename "$(echo "$line" | awk '{print $NF}')")
            local timestamp=$(echo "$line" | awk '{print $6, $7, $8}')
            echo "  • $filename ($timestamp)"
        done || true
    fi
}

# Recovery from crash
recover_from_crash() {
    log "🛡️  Crash Recovery Mode"
    echo ""
    
    if [ ! -d "$CRASH_RECOVERY_DIR" ]; then
        warn "No crash recovery directory found"
        return 1
    fi
    
    local recovery_files=$(ls -1 "$CRASH_RECOVERY_DIR"/*.jsonl 2>/dev/null | wc -l || echo 0)
    
    if [ "$recovery_files" -eq 0 ]; then
        log "✅ No crash recovery needed - no recovery files found"
        return 0
    fi
    
    log "📊 Found $recovery_files crash recovery files"
    
    # Group by session ID and get the latest for each
    for session_id in $(ls "$CRASH_RECOVERY_DIR"/*.jsonl 2>/dev/null | sed 's/.*\/\([^_]*\)_.*/\1/' | sort -u); do
        local latest_file=$(ls -t "$CRASH_RECOVERY_DIR/${session_id}_"*.jsonl 2>/dev/null | head -1)
        if [ -n "$latest_file" ]; then
            local target_file="$REALTIME_BACKUP_DIR/${session_id}.jsonl"
            
            # Copy latest crash recovery to main backup
            if cp "$latest_file" "$target_file"; then
                log "🔄 Recovered: $session_id"
            else
                error "❌ Failed to recover: $session_id"
            fi
        fi
    done
    
    log "✅ Crash recovery completed"
}

# Main function
main() {
    case "${1:-help}" in
        "start")
            start_background_monitor
            ;;
        "stop")
            stop_background_monitor
            ;;
        "status")
            show_monitor_status
            ;;
        "monitor")
            setup_monitoring
            monitor_conversations
            ;;
        "recover")
            recover_from_crash
            ;;
        "help"|"-h"|"--help")
            cat << 'EOF'
Claude Docker Real-Time Conversation Monitor

USAGE:
    ./conversation-monitor.sh [command]

COMMANDS:
    start           Start background monitoring
    stop            Stop background monitoring
    status          Show monitor status and recent backups
    monitor         Run monitoring in foreground (for testing)
    recover         Recover conversations from crash files
    help            Show this help

FEATURES:
    • Real-time monitoring of Docker conversations
    • Immediate backup on conversation changes
    • Crash recovery with timestamped backups
    • Background operation with status tracking
    • Protection against Mac crashes and RAM issues

BACKUP LOCATIONS:
    Real-time:      ~/.claude-docker-conversations/realtime/
    Crash recovery: ~/.claude-docker-conversations/crash-recovery/
    Monitor logs:   ~/.claude-docker-conversations/monitor.log

EXAMPLES:
    ./conversation-monitor.sh start     # Start background monitoring
    ./conversation-monitor.sh status    # Check status
    ./conversation-monitor.sh recover   # Recover from crash
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