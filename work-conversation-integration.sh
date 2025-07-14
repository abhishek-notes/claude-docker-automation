#!/bin/bash

# Work Conversation Integration
# Automatically saves all future conversations to Work directory with meaningful names

set -euo pipefail

WORK_CONVERSATIONS_DIR="/Users/abhishek/Work/claude-conversations"
CLAUDE_CONFIG_VOLUME="claude-code-config"
INTEGRATION_PID_FILE="$HOME/.claude-docker-conversations/work_integration.pid"
INTEGRATION_LOG_FILE="$HOME/.claude-docker-conversations/work_integration.log"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$INTEGRATION_LOG_FILE"; }

# Auto-save new conversations to Work directory with meaningful names
auto_save_to_work() {
    log "🔄 Starting Work directory auto-save (every 60s)"
    
    local last_check_file="$HOME/.claude-docker-conversations/last_work_check"
    touch "$last_check_file"
    
    while true; do
        # Check for new conversations
        docker run --rm \
            -v "$CLAUDE_CONFIG_VOLUME:/config:ro" \
            -v "$WORK_CONVERSATIONS_DIR:/work-conversations" \
            -v "$(dirname "$0"):/scripts:ro" \
            alpine sh -c '
            cd /config/projects/-workspace 2>/dev/null || exit 0
            
            for jsonl_file in *.jsonl; do
                if [ -f "$jsonl_file" ]; then
                    session_id="${jsonl_file%.jsonl}"
                    work_file="/work-conversations/conversations/temp_${session_id}.jsonl"
                    
                    # Copy if not exists or if source is newer
                    if [ ! -f "$work_file" ] || [ "$jsonl_file" -nt "$work_file" ]; then
                        echo "Auto-saving: $session_id"
                        cp "$jsonl_file" "$work_file"
                    fi
                fi
            done
        ' 2>/dev/null || true
        
        # Process temp files and rename them
        if [ -d "$WORK_CONVERSATIONS_DIR/conversations" ]; then
            for temp_file in "$WORK_CONVERSATIONS_DIR/conversations"/temp_*.jsonl; do
                if [ -f "$temp_file" ]; then
                    local session_id=$(basename "$temp_file" | sed 's/temp_//' | sed 's/.jsonl//')
                    local meaningful_name=$(extract_meaningful_name_from_file "$temp_file" "$session_id")
                    local final_file="$WORK_CONVERSATIONS_DIR/conversations/${meaningful_name}.jsonl"
                    
                    mv "$temp_file" "$final_file"
                    log "📝 Auto-saved: $meaningful_name"
                    
                    # Organize into topic folders
                    organize_single_conversation "$final_file" "$meaningful_name"
                fi
            done
        fi
        
        sleep 60
    done
}

# Extract meaningful name from a conversation file
extract_meaningful_name_from_file() {
    local jsonl_file="$1"
    local session_id="$2"
    
    if [ ! -f "$jsonl_file" ]; then
        echo "unknown-session_${session_id:0:8}"
        return
    fi
    
    # Extract summary and context (same logic as conversation-organizer.sh)
    local summary=$(head -1 "$jsonl_file" 2>/dev/null | jq -r '.summary // empty' 2>/dev/null || echo "")
    local timestamp=$(grep '"timestamp":' "$jsonl_file" | head -1 | jq -r '.timestamp' 2>/dev/null | cut -d'T' -f1 2>/dev/null || echo "")
    local task_content=$(grep -A5 -B5 '"content":".*CLAUDE_TASKS.md' "$jsonl_file" | head -20 2>/dev/null || echo "")
    local first_user_message=$(grep '"role":"user"' "$jsonl_file" | head -1 | jq -r '.message.content' 2>/dev/null | head -c 200 || echo "")
    
    # Determine project type
    local project_type=""
    local keywords=""
    
    if echo "$task_content $first_user_message $summary" | grep -qi "icici"; then
        project_type="ICICI"
        keywords="data-analysis"
    elif echo "$task_content $first_user_message $summary" | grep -qi "bank.*nifty\|nifty.*bank"; then
        project_type="BankNifty"
        keywords="options-backtesting"
    elif echo "$task_content $first_user_message $summary" | grep -qi "flat.*trade\|flattrade"; then
        project_type="FlatTrade"
        keywords="tick-data-system"
    elif echo "$task_content $first_user_message $summary" | grep -qi "trading\|backtest"; then
        project_type="Trading"
        keywords="strategy-analysis"
    else
        project_type="General"
        keywords="conversation"
    fi
    
    # Build name
    local name_parts=()
    [ -n "$timestamp" ] && name_parts+=("$timestamp")
    [ -n "$project_type" ] && name_parts+=("$project_type")
    [ -n "$keywords" ] && name_parts+=("$keywords")
    
    if [ ${#name_parts[@]} -gt 0 ]; then
        local result=$(IFS="_"; echo "${name_parts[*]}")
        echo "${result}_${session_id:0:8}"
    else
        echo "${session_id:0:8}_conversation"
    fi
}

# Organize a single conversation into topic folders
organize_single_conversation() {
    local jsonl_file="$1"
    local meaningful_name="$2"
    
    # Determine topic
    local topic="general"
    if echo "$meaningful_name" | grep -qi "icici\|banknifty\|trading\|flattrade"; then
        topic="trading"
    elif echo "$meaningful_name" | grep -qi "salesforce"; then
        topic="salesforce"
    elif echo "$meaningful_name" | grep -qi "wordpress"; then
        topic="wordpress"
    elif echo "$meaningful_name" | grep -qi "docker"; then
        topic="infrastructure"
    fi
    
    # Create topic directory and copy
    mkdir -p "$WORK_CONVERSATIONS_DIR/by-topic/$topic"
    cp "$jsonl_file" "$WORK_CONVERSATIONS_DIR/by-topic/$topic/"
    
    # Organize by date
    local date_part=$(echo "$meaningful_name" | grep -o '^[0-9]\{4\}-[0-9]\{2\}')
    if [ -n "$date_part" ]; then
        local year_month="${date_part}"
        mkdir -p "$WORK_CONVERSATIONS_DIR/by-date/$year_month"
        cp "$jsonl_file" "$WORK_CONVERSATIONS_DIR/by-date/$year_month/"
    fi
}

# Start background integration
start_integration() {
    if [ -f "$INTEGRATION_PID_FILE" ]; then
        local existing_pid=$(cat "$INTEGRATION_PID_FILE" 2>/dev/null || echo "")
        if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
            log "⚠️  Work integration already running (PID: $existing_pid)"
            return 1
        fi
    fi
    
    # Ensure Work directory exists
    mkdir -p "$WORK_CONVERSATIONS_DIR"/{conversations,by-topic,by-date,summaries}
    
    : > "$INTEGRATION_LOG_FILE"  # Clear log
    
    # Start in background
    auto_save_to_work &
    local pid=$!
    echo "$pid" > "$INTEGRATION_PID_FILE"
    
    log "✅ Work integration started (PID: $pid)"
    log "📁 Auto-saving to: $WORK_CONVERSATIONS_DIR"
    log "⏰ Check interval: 60 seconds"
    
    echo ""
    echo -e "${BLUE}💡 All future conversations will be automatically saved to Work directory${NC}"
    echo -e "${BLUE}💡 Stop with: $0 stop${NC}"
    echo -e "${BLUE}💡 Status: $0 status${NC}"
}

# Stop background integration
stop_integration() {
    if [ -f "$INTEGRATION_PID_FILE" ]; then
        local pid=$(cat "$INTEGRATION_PID_FILE" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            log "🛑 Work integration stopped (PID: $pid)"
        else
            log "⚠️  Integration process not found"
        fi
        rm -f "$INTEGRATION_PID_FILE"
    else
        log "⚠️  No PID file found"
    fi
}

# Show status
show_status() {
    log "📊 Work Integration Status"
    echo ""
    
    if [ -f "$INTEGRATION_PID_FILE" ]; then
        local pid=$(cat "$INTEGRATION_PID_FILE" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}✅ Work integration running (PID: $pid)${NC}"
            echo -e "${BLUE}📁 Auto-saving to: $WORK_CONVERSATIONS_DIR${NC}"
        else
            echo -e "${RED}❌ Integration not running (stale PID)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Work integration not started${NC}"
    fi
    
    if [ -d "$WORK_CONVERSATIONS_DIR" ]; then
        local count=$(ls "$WORK_CONVERSATIONS_DIR/conversations"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${BLUE}💾 Conversations in Work: $count files${NC}"
    fi
    
    echo ""
    if [ -f "$INTEGRATION_LOG_FILE" ]; then
        echo -e "${BLUE}📜 Recent log entries:${NC}"
        tail -5 "$INTEGRATION_LOG_FILE" 2>/dev/null || echo "  No log entries"
    fi
}

# Main
case "${1:-help}" in
    "start")
        start_integration
        ;;
    "stop")
        stop_integration
        ;;
    "status")
        show_status
        ;;
    "help"|"-h"|"--help")
        cat << 'EOF'
Work Conversation Integration - Auto-save conversations to Work directory

USAGE:
    ./work-conversation-integration.sh [command]

COMMANDS:
    start       Start automatic Work directory integration
    stop        Stop automatic integration
    status      Show integration status
    help        Show this help

FEATURES:
    • Automatically saves all new conversations to Work directory
    • Creates meaningful names in real-time
    • Organizes by topic and date automatically
    • Runs in background while you work
    • 60-second check interval

WORKFLOW:
    1. ./work-conversation-integration.sh start
    2. Start Claude sessions as normal
    3. Conversations automatically appear in /Users/abhishek/Work/claude-conversations/
    4. Use meaningful names like 2025-07-14_ICICI_data-analysis_1db5a5c2.jsonl

This ensures all future conversations are immediately accessible to new Claude sessions.
EOF
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use 'help' for usage."
        exit 1
        ;;
esac