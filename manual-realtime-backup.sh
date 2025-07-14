#!/bin/bash

# Manual Real-Time Backup for Current Session
# Run this periodically while working to backup your current conversation

set -euo pipefail

CLAUDE_CONFIG_VOLUME="claude-code-config"
BACKUP_DIR="$HOME/.claude-docker-conversations"
REALTIME_DIR="$BACKUP_DIR/realtime"
WORK_CONVERSATIONS_DIR="/Users/abhishek/Work/claude-conversations"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }

# Extract meaningful name from conversation file
extract_meaningful_name() {
    local jsonl_file="$1"
    local session_id="$2"
    
    if [ ! -f "$jsonl_file" ]; then
        echo "unknown-session_${session_id:0:8}"
        return
    fi
    
    # Extract summary, timestamp, and content
    local summary=$(head -1 "$jsonl_file" 2>/dev/null | jq -r '.summary // empty' 2>/dev/null || echo "")
    local timestamp=$(grep '"timestamp":' "$jsonl_file" | head -1 | jq -r '.timestamp' 2>/dev/null | cut -d'T' -f1 2>/dev/null || echo "")
    local task_content=$(grep -A5 -B5 '"content":".*CLAUDE_TASKS.md' "$jsonl_file" | head -20 2>/dev/null || echo "")
    local first_user_message=$(grep '"role":"user"' "$jsonl_file" | head -1 | jq -r '.message.content' 2>/dev/null | head -c 200 || echo "")
    
    # Determine project type and keywords
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
    elif echo "$task_content $first_user_message $summary" | grep -qi "salesforce"; then
        project_type="Salesforce"
        keywords="integration-dev"
    elif echo "$task_content $first_user_message $summary" | grep -qi "wordpress"; then
        project_type="WordPress"
        keywords="content-management"
    elif echo "$task_content $first_user_message $summary" | grep -qi "docker"; then
        project_type="Docker"
        keywords="automation-system"
    else
        project_type="General"
        keywords="conversation"
    fi
    
    # Build meaningful name
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

# Determine topic category
get_topic_category() {
    local meaningful_name="$1"
    
    if echo "$meaningful_name" | grep -qi "icici\|banknifty\|trading\|flattrade"; then
        echo "trading"
    elif echo "$meaningful_name" | grep -qi "salesforce"; then
        echo "salesforce"
    elif echo "$meaningful_name" | grep -qi "wordpress"; then
        echo "wordpress"
    elif echo "$meaningful_name" | grep -qi "docker"; then
        echo "infrastructure"
    elif echo "$meaningful_name" | grep -qi "development"; then
        echo "development"
    elif echo "$meaningful_name" | grep -qi "data.*analysis"; then
        echo "data-analysis"
    else
        echo "general"
    fi
}

# Create directories
mkdir -p "$REALTIME_DIR"
mkdir -p "$WORK_CONVERSATIONS_DIR"/{conversations,by-topic/{trading,development,salesforce,wordpress,infrastructure,data-analysis,general},by-date}

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

# Get the 3 most recent conversations and backup to both realtime and Work directory
backup_count=0
work_backup_count=0

# First, backup to realtime (existing functionality)
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

# Now process files and save to Work directory with meaningful names
log "💾 Saving to Work directory with meaningful names..."
for jsonl_file in "$REALTIME_DIR"/*.jsonl; do
    if [ -f "$jsonl_file" ]; then
        session_id=$(basename "$jsonl_file" .jsonl)
        meaningful_name=$(extract_meaningful_name "$jsonl_file" "$session_id")
        topic=$(get_topic_category "$meaningful_name")
        
        # Save to Work conversations directory
        work_file="$WORK_CONVERSATIONS_DIR/conversations/${meaningful_name}.jsonl"
        cp "$jsonl_file" "$work_file"
        
        # Organize by topic
        cp "$jsonl_file" "$WORK_CONVERSATIONS_DIR/by-topic/$topic/${meaningful_name}.jsonl"
        
        # Organize by date
        date_part=$(echo "$meaningful_name" | grep -o '^[0-9]\{4\}-[0-9]\{2\}')
        if [ -n "$date_part" ]; then
            mkdir -p "$WORK_CONVERSATIONS_DIR/by-date/$date_part"
            cp "$jsonl_file" "$WORK_CONVERSATIONS_DIR/by-date/$date_part/${meaningful_name}.jsonl"
        fi
        
        ((work_backup_count++))
        log "📝 Saved to Work: $meaningful_name → Topic: $topic"
    fi
done

# Show current status
echo ""
echo -e "${BLUE}📊 Backup Status:${NC}"
echo -e "${BLUE}📁 Real-time:${NC} $REALTIME_DIR ($backup_count files)"
echo -e "${BLUE}📁 Work directory:${NC} $WORK_CONVERSATIONS_DIR ($work_backup_count files)"

if [ "$work_backup_count" -gt 0 ]; then
    echo ""
    echo -e "${BLUE}📋 Recent Work directory conversations:${NC}"
    ls -lt "$WORK_CONVERSATIONS_DIR/conversations"/*.jsonl 2>/dev/null | head -3 | while read -r line; do
        filename=$(basename "$(echo "$line" | awk '{print $NF}')" .jsonl)
        timestamp=$(echo "$line" | awk '{print $6, $7, $8}')
        size=$(echo "$line" | awk '{print $5}')
        echo "  • $filename ($timestamp, $size bytes)"
    done
fi

echo ""
echo -e "${GREEN}💡 TIP:${NC} Your conversations are now accessible to Claude in: $WORK_CONVERSATIONS_DIR"
echo -e "${GREEN}💡 CLAUDE:${NC} Say 'Claude, read claude-conversations/conversations/FILENAME.jsonl' in any session"