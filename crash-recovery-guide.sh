#!/bin/bash

# Claude Docker Crash Recovery Guide and Helper
# Helps recover conversations after Mac crashes, RAM issues, or Docker failures

set -euo pipefail

BACKUP_DIR="$HOME/.claude-docker-conversations"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN:${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"; }

# Check system status after crash
check_system_status() {
    log "🔍 Checking system status after potential crash..."
    echo ""
    
    # Check Docker status
    if docker ps >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker is running${NC}"
        local running_containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep claude || echo "None")
        if [ "$running_containers" != "None" ]; then
            echo -e "${BLUE}🐳 Running Claude containers:${NC}"
            echo "$running_containers"
        else
            echo -e "${YELLOW}⚠️  No Claude containers currently running${NC}"
        fi
    else
        echo -e "${RED}❌ Docker is not running${NC}"
        echo "   💡 Start Docker Desktop to recover conversations"
    fi
    echo ""
    
    # Check monitoring status
    if [ -f "$BACKUP_DIR/monitor_state.json" ]; then
        local monitor_status=$(jq -r '.status // "unknown"' "$BACKUP_DIR/monitor_state.json" 2>/dev/null)
        local monitor_pid=$(jq -r '.monitor_pid // "none"' "$BACKUP_DIR/monitor_state.json" 2>/dev/null)
        
        echo -e "${BLUE}📊 Monitor Status:${NC} $monitor_status"
        
        if [ "$monitor_pid" != "none" ] && [ "$monitor_status" = "monitoring" ]; then
            if kill -0 "$monitor_pid" 2>/dev/null; then
                echo -e "${GREEN}✅ Real-time monitor is running (PID: $monitor_pid)${NC}"
            else
                echo -e "${RED}❌ Monitor process crashed (PID: $monitor_pid not found)${NC}"
                echo "   💡 Real-time monitoring was interrupted"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  No monitor state found${NC}"
    fi
    echo ""
    
    # Check backup integrity
    check_backup_integrity
}

# Check backup integrity
check_backup_integrity() {
    log "🔍 Checking backup integrity..."
    
    if [ ! -d "$BACKUP_DIR" ]; then
        warn "No backup directory found"
        return 1
    fi
    
    local conv_dir="$BACKUP_DIR/conversations"
    local realtime_dir="$BACKUP_DIR/realtime"
    local crash_dir="$BACKUP_DIR/crash-recovery"
    
    # Regular backups
    if [ -d "$conv_dir" ]; then
        local regular_count=$(ls -1 "$conv_dir"/*.jsonl 2>/dev/null | wc -l || echo 0)
        echo -e "${BLUE}📁 Regular backups:${NC} $regular_count conversations"
    fi
    
    # Real-time backups
    if [ -d "$realtime_dir" ]; then
        local realtime_count=$(ls -1 "$realtime_dir"/*.jsonl 2>/dev/null | wc -l || echo 0)
        realtime_count=$(echo "$realtime_count" | tr -d ' ')  # Remove any whitespace
        echo -e "${BLUE}⚡ Real-time backups:${NC} $realtime_count conversations"
    fi
    
    # Crash recovery files
    if [ -d "$crash_dir" ]; then
        local crash_count=$(ls -1 "$crash_dir"/*.jsonl 2>/dev/null | wc -l || echo 0)
        crash_count=$(echo "$crash_count" | tr -d ' ')  # Remove any whitespace
        echo -e "${BLUE}🛡️  Crash recovery files:${NC} $crash_count files"
        
        if [ "$crash_count" -gt 0 ] 2>/dev/null; then
            echo -e "${YELLOW}   💡 Crash recovery files available - run recovery${NC}"
        fi
    fi
    echo ""
}

# Full crash recovery procedure
full_crash_recovery() {
    log "🛡️  Starting full crash recovery procedure..."
    echo ""
    
    # Step 1: Check system status
    check_system_status
    
    # Step 2: Start Docker if not running
    if ! docker ps >/dev/null 2>&1; then
        warn "Docker is not running. Please start Docker Desktop first."
        echo "   Then run this script again."
        return 1
    fi
    
    # Step 3: Run crash recovery
    if [ -f "$SCRIPT_DIR/conversation-monitor.sh" ]; then
        log "🔄 Running conversation recovery..."
        "$SCRIPT_DIR/conversation-monitor.sh" recover
    fi
    
    # Step 4: Full backup to ensure everything is saved
    if [ -f "$SCRIPT_DIR/conversation-backup.sh" ]; then
        log "💾 Running full backup to consolidate all conversations..."
        "$SCRIPT_DIR/conversation-backup.sh" backup
    fi
    
    # Step 5: Restart monitoring
    if [ -f "$SCRIPT_DIR/conversation-monitor.sh" ]; then
        log "🎯 Restarting real-time monitoring..."
        "$SCRIPT_DIR/conversation-monitor.sh" start
    fi
    
    echo ""
    log "✅ Crash recovery completed!"
    echo ""
    echo -e "${BLUE}💡 What happened during recovery:${NC}"
    echo "   1. Checked system and Docker status"
    echo "   2. Recovered conversations from crash files"
    echo "   3. Consolidated all backups"
    echo "   4. Restarted real-time monitoring"
    echo ""
    echo -e "${BLUE}🔍 To find your specific conversations:${NC}"
    echo "   ./claude-backup-alias.sh find \"dashboard\""
    echo "   ./claude-backup-alias.sh find \"bank-nifty\""
    echo "   ./claude-backup-alias.sh list"
}

# Emergency backup export
emergency_export() {
    log "🚨 Emergency conversation export..."
    
    local export_dir="$HOME/Desktop/Claude_Emergency_Export_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$export_dir"
    
    # Export all conversation formats
    if [ -d "$BACKUP_DIR/conversations" ]; then
        cp -r "$BACKUP_DIR/conversations" "$export_dir/"
        log "📁 Copied regular backups"
    fi
    
    if [ -d "$BACKUP_DIR/realtime" ]; then
        cp -r "$BACKUP_DIR/realtime" "$export_dir/"
        log "⚡ Copied real-time backups"
    fi
    
    if [ -d "$BACKUP_DIR/crash-recovery" ]; then
        cp -r "$BACKUP_DIR/crash-recovery" "$export_dir/"
        log "🛡️  Copied crash recovery files"
    fi
    
    if [ -d "$BACKUP_DIR/exports" ]; then
        cp -r "$BACKUP_DIR/exports" "$export_dir/"
        log "📋 Copied readable summaries"
    fi
    
    # Create recovery instructions
    cat > "$export_dir/RECOVERY_INSTRUCTIONS.md" << 'EOF'
# Claude Conversation Emergency Export

This export contains all your Claude conversations backed up from Docker containers.

## Contents

- `conversations/` - Regular backup files (JSONL format)
- `realtime/` - Real-time backup files (JSONL format)  
- `crash-recovery/` - Crash recovery files (JSONL format)
- `exports/` - Human-readable summaries (Markdown format)

## Recovery Steps

1. Start Docker Desktop
2. Run: `./claude-docker-persistent.sh backup restore <session-id>`
3. Or manually copy JSONL files back to Docker volume

## Finding Conversations

Search files for keywords:
```bash
grep -l "dashboard" conversations/*.jsonl
grep -l "bank-nifty" conversations/*.jsonl
```

## File Format

Each JSONL file contains one JSON object per line with:
- User messages and Claude responses
- Timestamps and metadata
- Tool usage and results

## Support

If you need help recovering specific conversations, check the main claude-docker-automation repository for latest recovery scripts.
EOF
    
    log "✅ Emergency export completed!"
    log "📁 Location: $export_dir"
    echo ""
    echo -e "${BLUE}🎯 Emergency export contains:${NC}"
    echo "   • All conversation backups in multiple formats"
    echo "   • Recovery instructions"
    echo "   • Searchable and readable files"
    echo ""
    echo -e "${BLUE}💡 Next steps:${NC}"
    echo "   1. Keep this export safe as a backup"
    echo "   2. Run full recovery when Docker is available"
    echo "   3. Search files for specific conversations"
}

# Show recovery options
show_recovery_options() {
    cat << 'EOF'
🛡️  Claude Docker Crash Recovery Guide

WHAT TO DO AFTER MAC CRASH / RAM ISSUES:

1. IMMEDIATE STEPS:
   ✅ Restart your Mac completely
   ✅ Start Docker Desktop
   ✅ Run this script with 'recover' command

2. RECOVERY OPTIONS:
   
   a) FULL AUTOMATIC RECOVERY:
      ./crash-recovery-guide.sh recover
      → Recovers all conversations automatically
      
   b) CHECK STATUS ONLY:
      ./crash-recovery-guide.sh status
      → Shows what was recovered/lost
      
   c) EMERGENCY EXPORT:
      ./crash-recovery-guide.sh export
      → Creates Desktop backup of all conversations
      
   d) MANUAL SEARCH:
      ./claude-backup-alias.sh find "your-topic"
      → Find specific conversations

3. PREVENTION FOR FUTURE:
   ✅ Real-time monitoring runs automatically
   ✅ Conversations backed up every 10 seconds
   ✅ Crash recovery files created continuously
   ✅ Multiple backup locations maintained

4. YOUR BANK-NIFTY CONVERSATION:
   Session ID: 54f1b9b6-a2a2-4a91-9836-f98330b15c20
   Search with: ./claude-backup-alias.sh find "parquet"

COMMANDS:
   status     Check system status after crash
   recover    Run full automatic recovery
   export     Create emergency export on Desktop
   help       Show this guide

The system is designed to survive Mac crashes, RAM issues, and Docker failures.
Your conversations are backed up in multiple locations with crash recovery.
EOF
}

# Main function
main() {
    case "${1:-help}" in
        "status")
            check_system_status
            ;;
        "recover")
            full_crash_recovery
            ;;
        "export")
            emergency_export
            ;;
        "help"|"-h"|"--help")
            show_recovery_options
            ;;
        *)
            show_recovery_options
            ;;
    esac
}

# Run main function
main "$@"