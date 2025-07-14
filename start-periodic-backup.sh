#!/bin/bash

# Periodic Backup Starter - Simple and Reliable
# Runs manual backup every 30 seconds while you work

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$HOME/.claude-docker-conversations/periodic_backup.pid"
LOG_FILE="$HOME/.claude-docker-conversations/periodic_backup.log"
INTERVAL=30  # 30 seconds

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"; }

# Periodic backup function
run_periodic_backup() {
    log "🔄 Starting periodic backup (every ${INTERVAL}s)"
    
    while true; do
        # Run the manual backup script
        if "$SCRIPT_DIR/manual-realtime-backup.sh" >> "$LOG_FILE" 2>&1; then
            echo "[$(date '+%H:%M:%S')] ✅ Backup successful" >> "$LOG_FILE"
        else
            echo "[$(date '+%H:%M:%S')] ⚠️  Backup failed" >> "$LOG_FILE"
        fi
        
        sleep "$INTERVAL"
    done
}

# Start periodic backup
start_periodic() {
    if [ -f "$PID_FILE" ]; then
        local existing_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
            log "⚠️  Periodic backup already running (PID: $existing_pid)"
            return 1
        fi
    fi
    
    : > "$LOG_FILE"  # Clear log
    
    # Start in background
    run_periodic_backup &
    local pid=$!
    echo "$pid" > "$PID_FILE"
    
    log "✅ Periodic backup started (PID: $pid)"
    log "📁 Log file: $LOG_FILE"
    log "⏰ Backup interval: ${INTERVAL} seconds"
    
    echo ""
    echo -e "${BLUE}💡 While this runs, your conversations will be backed up every 30 seconds${NC}"
    echo -e "${BLUE}💡 Stop with: $0 stop${NC}"
    echo -e "${BLUE}💡 Status: $0 status${NC}"
}

# Stop periodic backup
stop_periodic() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            log "🛑 Periodic backup stopped (PID: $pid)"
        else
            log "⚠️  Backup process not found"
        fi
        rm -f "$PID_FILE"
    else
        log "⚠️  No PID file found"
    fi
}

# Show status
show_status() {
    log "📊 Periodic Backup Status"
    echo ""
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}✅ Periodic backup running (PID: $pid)${NC}"
            echo -e "${BLUE}⏰ Interval: ${INTERVAL} seconds${NC}"
        else
            echo -e "${RED}❌ Backup not running (stale PID)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Periodic backup not started${NC}"
    fi
    
    echo ""
    if [ -f "$LOG_FILE" ]; then
        echo -e "${BLUE}📜 Recent log entries:${NC}"
        tail -5 "$LOG_FILE" 2>/dev/null || echo "  No log entries"
    fi
    
    # Show realtime backup status
    local realtime_dir="$HOME/.claude-docker-conversations/realtime"
    if [ -d "$realtime_dir" ]; then
        local count=$(ls "$realtime_dir"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
        echo ""
        echo -e "${BLUE}💾 Current real-time backups: $count files${NC}"
        
        if [ "$count" -gt 0 ]; then
            echo -e "${BLUE}📋 Most recent:${NC}"
            ls -lt "$realtime_dir"/*.jsonl 2>/dev/null | head -2 | while read -r line; do
                filename=$(basename "$(echo "$line" | awk '{print $NF}')" .jsonl)
                timestamp=$(echo "$line" | awk '{print $6, $7, $8}')
                echo "  • $filename ($timestamp)"
            done
        fi
    fi
}

# Main
case "${1:-help}" in
    "start")
        start_periodic
        ;;
    "stop")
        stop_periodic
        ;;
    "status")
        show_status
        ;;
    "help"|"-h"|"--help")
        cat << 'EOF'
Periodic Backup for Real-Time Protection

USAGE:
    ./start-periodic-backup.sh [command]

COMMANDS:
    start       Start periodic backup (every 30 seconds)
    stop        Stop periodic backup
    status      Show backup status
    help        Show this help

FEATURES:
    • Backs up conversations every 30 seconds
    • Runs in background while you work
    • Simple and reliable approach
    • Automatic logging

This is the solution for real-time protection while the
automatic monitor is being improved.
EOF
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use 'help' for usage."
        exit 1
        ;;
esac