#!/bin/bash

# Simple Real-Time Conversation Monitor
# Fixed version that works reliably with Mac/Docker

set -euo pipefail

CLAUDE_CONFIG_VOLUME="claude-code-config"
BACKUP_DIR="$HOME/.claude-docker-conversations"
REALTIME_BACKUP_DIR="$BACKUP_DIR/realtime"
MONITOR_INTERVAL=15  # 15 seconds - more reliable
PID_FILE="$BACKUP_DIR/simple_monitor.pid"
LOG_FILE="$BACKUP_DIR/simple_monitor.log"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN:${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"; }

# Setup
setup_monitor() {
    mkdir -p "$REALTIME_BACKUP_DIR"
    : > "$LOG_FILE"  # Clear log file
    log "🔧 Simple real-time monitor starting..."
}

# Simple monitoring loop
monitor_loop() {
    local backup_count=0
    
    while true; do
        # Check if Docker is available
        if ! docker ps >/dev/null 2>&1; then
            warn "Docker not available, waiting..."
            sleep "$MONITOR_INTERVAL"
            continue
        fi
        
        # Check if volume exists
        if ! docker volume inspect "$CLAUDE_CONFIG_VOLUME" >/dev/null 2>&1; then
            warn "Volume $CLAUDE_CONFIG_VOLUME not found, waiting..."
            sleep "$MONITOR_INTERVAL"
            continue
        fi
        
        # Get list of JSONL files and backup any changes
        local current_time=$(date +%s)
        
        # Use a simple approach - check all files and backup if newer
        docker run --rm \
            -v "$CLAUDE_CONFIG_VOLUME:/config:ro" \
            -v "$REALTIME_BACKUP_DIR:/realtime" \
            alpine sh -c '
            cd /config/projects/-workspace 2>/dev/null || exit 0
            for jsonl_file in *.jsonl 2>/dev/null; do
                if [ -f "$jsonl_file" ]; then
                    session_id="${jsonl_file%.jsonl}"
                    realtime_file="/realtime/${session_id}.jsonl"
                    
                    # Check if file changed (simple size/time comparison)
                    if [ ! -f "$realtime_file" ] || [ "$jsonl_file" -nt "$realtime_file" ]; then
                        echo "Backing up: $session_id"
                        cp "$jsonl_file" "$realtime_file.tmp" 2>/dev/null && mv "$realtime_file.tmp" "$realtime_file" 2>/dev/null
                    fi
                fi
            done
        ' 2>/dev/null && {
            # Count successful backups
            local new_count=$(ls "$REALTIME_BACKUP_DIR"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
            if [ "$new_count" != "$backup_count" ]; then
                backup_count="$new_count"
                log "💾 Real-time backup: $backup_count conversations monitored"
            fi
        } || warn "Backup operation failed"
        
        # Status update every 5 minutes
        if [ $((current_time % 300)) -lt "$MONITOR_INTERVAL" ]; then
            log "📈 Monitoring active: $backup_count conversations tracked"
        fi
        
        sleep "$MONITOR_INTERVAL"
    done
}

# Start monitoring in background
start_monitor() {
    if [ -f "$PID_FILE" ]; then
        local existing_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
            log "⚠️  Monitor already running (PID: $existing_pid)"
            return 1
        fi
    fi
    
    setup_monitor
    
    # Start in background
    (monitor_loop) &
    local pid=$!
    echo "$pid" > "$PID_FILE"
    
    log "✅ Simple monitor started (PID: $pid)"
    log "📁 Log file: $LOG_FILE"
    log "💾 Real-time backups: $REALTIME_BACKUP_DIR"
}

# Stop monitoring
stop_monitor() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            log "🛑 Monitor stopped (PID: $pid)"
        else
            warn "Monitor process not found"
        fi
        rm -f "$PID_FILE"
    else
        warn "No PID file found"
    fi
}

# Show status
show_status() {
    log "📊 Simple Real-Time Monitor Status"
    echo ""
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}✅ Monitor running (PID: $pid)${NC}"
        else
            echo -e "${RED}❌ Monitor not running (stale PID file)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Monitor not started${NC}"
    fi
    
    if [ -d "$REALTIME_BACKUP_DIR" ]; then
        local count=$(ls "$REALTIME_BACKUP_DIR"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${BLUE}💾 Real-time backups: $count files${NC}"
        
        if [ "$count" -gt 0 ]; then
            echo -e "${BLUE}📋 Recent real-time backups:${NC}"
            ls -lt "$REALTIME_BACKUP_DIR"/*.jsonl 2>/dev/null | head -5 | while read -r line; do
                local filename=$(basename "$(echo "$line" | awk '{print $NF}')" .jsonl)
                local timestamp=$(echo "$line" | awk '{print $6, $7, $8}')
                echo "  • $filename ($timestamp)"
            done
        fi
    fi
    
    echo ""
    echo -e "${BLUE}📜 Recent log entries:${NC}"
    tail -5 "$LOG_FILE" 2>/dev/null || echo "  No log entries"
}

# Main
case "${1:-help}" in
    "start")
        start_monitor
        ;;
    "stop")
        stop_monitor
        ;;
    "status")
        show_status
        ;;
    "help"|"-h"|"--help")
        cat << 'EOF'
Simple Real-Time Conversation Monitor

USAGE:
    ./simple-realtime-monitor.sh [command]

COMMANDS:
    start       Start background monitoring
    stop        Stop background monitoring  
    status      Show monitor status
    help        Show this help

FEATURES:
    • Monitors conversations every 15 seconds
    • Simple and reliable approach
    • Real-time backups to ~/.claude-docker-conversations/realtime/
    • Background operation with logging
EOF
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use 'help' for usage."
        exit 1
        ;;
esac