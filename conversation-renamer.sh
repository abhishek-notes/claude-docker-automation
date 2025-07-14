#!/bin/bash

# Conversation Renamer - Create meaningful names for conversation files
# Extracts summaries, timestamps, and keywords to generate readable filenames

set -euo pipefail

BACKUP_DIR="$HOME/.claude-docker-conversations"
CONVERSATIONS_DIR="$BACKUP_DIR/conversations"
REALTIME_DIR="$BACKUP_DIR/realtime"
RENAMED_DIR="$BACKUP_DIR/named-conversations"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN:${NC} $1"; }

# Extract meaningful name from conversation file
extract_conversation_name() {
    local jsonl_file="$1"
    local session_id="$2"
    
    if [ ! -f "$jsonl_file" ]; then
        echo "unknown-session"
        return
    fi
    
    # Extract summary from first line (if available)
    local summary=$(head -1 "$jsonl_file" 2>/dev/null | jq -r '.summary // empty' 2>/dev/null || echo "")
    
    # Extract timestamp from session data
    local timestamp=$(grep '"timestamp":' "$jsonl_file" | head -1 | jq -r '.timestamp' 2>/dev/null | cut -d'T' -f1 2>/dev/null || echo "")
    
    # Extract working directory or project context
    local project_context=""
    local cwd=$(grep '"cwd":' "$jsonl_file" | head -1 | jq -r '.cwd // empty' 2>/dev/null || echo "")
    if [ -n "$cwd" ] && [ "$cwd" != "/workspace" ]; then
        project_context=$(basename "$cwd" 2>/dev/null || echo "")
    fi
    
    # Extract task content for keywords
    local task_content=$(grep -o '"content":"[^"]*CLAUDE_TASKS.md[^"]*"' "$jsonl_file" | head -1 | sed 's/.*CLAUDE_TASKS.md[^"]*//g' 2>/dev/null || echo "")
    
    # Build meaningful name
    local name_parts=()
    
    # Add timestamp
    if [ -n "$timestamp" ]; then
        name_parts+=("$timestamp")
    fi
    
    # Add project context
    if [ -n "$project_context" ]; then
        name_parts+=("$project_context")
    fi
    
    # Add summary or extract keywords
    if [ -n "$summary" ] && [ "$summary" != "null" ]; then
        # Clean summary for filename
        local clean_summary=$(echo "$summary" | tr ' ' '-' | tr -cd '[:alnum:]-' | cut -c1-50)
        if [ -n "$clean_summary" ]; then
            name_parts+=("$clean_summary")
        fi
    else
        # Extract keywords from content
        local keywords=$(echo "$task_content" | grep -oE '\b(dashboard|api|test|fix|bank|nifty|icici|data|analysis|backtest|trading)\b' | head -3 | tr '\n' '-' | sed 's/-$//' 2>/dev/null || echo "")
        if [ -n "$keywords" ]; then
            name_parts+=("$keywords")
        fi
    fi
    
    # If we have parts, join them; otherwise use session ID
    if [ ${#name_parts[@]} -gt 0 ]; then
        local result=$(IFS="_"; echo "${name_parts[*]}")
        # Clean up the result
        result=$(echo "$result" | tr -cd '[:alnum:]_-' | sed 's/_{2,}/_/g' | sed 's/^_\|_$//g')
        echo "${result}_${session_id:0:8}"
    else
        echo "${session_id:0:8}_conversation"
    fi
}

# Create renamed version of a conversation file
rename_conversation() {
    local source_file="$1"
    local source_dir="$2"
    local session_id=$(basename "$source_file" .jsonl)
    
    log "📝 Processing: $session_id"
    
    # Extract meaningful name
    local meaningful_name=$(extract_conversation_name "$source_file" "$session_id")
    
    # Create target filename
    local target_file="$RENAMED_DIR/${meaningful_name}.jsonl"
    
    # Copy file with new name
    cp "$source_file" "$target_file"
    
    # Create metadata file
    cat > "${target_file%.jsonl}.meta" << EOF
# Conversation Metadata
Original ID: $session_id
Original File: $(basename "$source_file")
Source Directory: $source_dir
Renamed: $(date)
Size: $(wc -c < "$source_file") bytes
Messages: $(wc -l < "$source_file") lines

# Summary
$(head -1 "$source_file" 2>/dev/null | jq -r '.summary // "No summary available"' 2>/dev/null || echo "No summary available")

# First few messages
$(head -3 "$source_file" | jq -r '. | if .type == "user" then "USER: " + (.message.content // "No content") elif .type == "assistant" then "ASSISTANT: " + ((.message.content[0].text // .message.content // "No content") | .[0:200]) else "OTHER: " + (.summary // "No content") end' 2>/dev/null || echo "No messages found")
EOF
    
    echo "  → $meaningful_name"
}

# Rename all conversations in a directory
rename_conversations_in_dir() {
    local source_dir="$1"
    local dir_name="$2"
    
    if [ ! -d "$source_dir" ]; then
        warn "$dir_name directory not found: $source_dir"
        return
    fi
    
    local count=0
    log "🔍 Processing $dir_name conversations..."
    
    for jsonl_file in "$source_dir"/*.jsonl; do
        if [ -f "$jsonl_file" ]; then
            rename_conversation "$jsonl_file" "$dir_name"
            ((count++))
        fi
    done
    
    log "✅ Processed $count conversations from $dir_name"
}

# Show renamed conversations
show_renamed_conversations() {
    log "📋 Renamed Conversations:"
    echo ""
    
    if [ ! -d "$RENAMED_DIR" ] || [ -z "$(ls -A "$RENAMED_DIR" 2>/dev/null)" ]; then
        echo "  No renamed conversations found"
        return
    fi
    
    ls -lt "$RENAMED_DIR"/*.jsonl 2>/dev/null | while read -r line; do
        local filename=$(basename "$(echo "$line" | awk '{print $NF}')" .jsonl)
        local timestamp=$(echo "$line" | awk '{print $6, $7, $8}')
        local size=$(echo "$line" | awk '{print $5}')
        
        echo -e "  ${BLUE}$filename${NC}"
        echo "    📅 $timestamp, 💾 $size bytes"
        
        # Show summary if meta file exists
        local meta_file="$RENAMED_DIR/${filename}.meta"
        if [ -f "$meta_file" ]; then
            local summary=$(grep -A1 "# Summary" "$meta_file" | tail -1)
            if [ -n "$summary" ] && [ "$summary" != "No summary available" ]; then
                echo "    📝 $summary"
            fi
        fi
        echo ""
    done
}

# Search renamed conversations
search_renamed_conversations() {
    local search_term="$1"
    
    log "🔍 Searching for: '$search_term'"
    echo ""
    
    if [ ! -d "$RENAMED_DIR" ]; then
        warn "No renamed conversations directory found"
        return
    fi
    
    # Search in filenames
    echo -e "${BLUE}📁 Filename matches:${NC}"
    find "$RENAMED_DIR" -name "*${search_term}*" -name "*.jsonl" 2>/dev/null | while read -r file; do
        local filename=$(basename "$file" .jsonl)
        echo "  • $filename"
    done
    
    echo ""
    
    # Search in metadata
    echo -e "${BLUE}📝 Content matches:${NC}"
    grep -l "$search_term" "$RENAMED_DIR"/*.meta 2>/dev/null | while read -r meta_file; do
        local jsonl_file="${meta_file%.meta}.jsonl"
        local filename=$(basename "$jsonl_file" .jsonl)
        echo "  • $filename"
    done || echo "  No content matches found"
}

# Main function
main() {
    case "${1:-help}" in
        "rename"|"r")
            mkdir -p "$RENAMED_DIR"
            log "🚀 Starting conversation renaming process..."
            
            # Rename conversations from both directories
            rename_conversations_in_dir "$CONVERSATIONS_DIR" "conversations"
            rename_conversations_in_dir "$REALTIME_DIR" "realtime"
            
            echo ""
            show_renamed_conversations
            
            echo ""
            log "💡 Use './conversation-renamer.sh list' to see all renamed conversations"
            log "💡 Use './conversation-renamer.sh search <term>' to find specific conversations"
            ;;
        "list"|"l")
            show_renamed_conversations
            ;;
        "search"|"s")
            if [ -z "${2:-}" ]; then
                echo "Usage: $0 search <search-term>"
                exit 1
            fi
            search_renamed_conversations "$2"
            ;;
        "clean"|"c")
            if [ -d "$RENAMED_DIR" ]; then
                read -p "Remove all renamed conversations? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    rm -rf "$RENAMED_DIR"
                    log "🗑️  Cleaned up renamed conversations"
                else
                    log "❌ Cleanup cancelled"
                fi
            else
                log "ℹ️  No renamed conversations to clean"
            fi
            ;;
        "help"|"h")
            cat << 'EOF'
Conversation Renamer - Make conversation files identifiable

USAGE:
    ./conversation-renamer.sh <command> [args]

COMMANDS:
    rename, r               Rename all conversations with meaningful names
    list, l                 List all renamed conversations
    search, s <term>        Search renamed conversations by filename or content
    clean, c                Remove all renamed conversations
    help, h                 Show this help

EXAMPLES:
    ./conversation-renamer.sh rename        # Create meaningful names for all conversations
    ./conversation-renamer.sh list          # Show all renamed conversations
    ./conversation-renamer.sh search icici  # Find conversations about ICICI
    ./conversation-renamer.sh search dashboard  # Find dashboard-related conversations

FEATURES:
    • Extracts summaries and keywords from conversation content
    • Uses timestamps and project context for meaningful names
    • Creates metadata files with conversation details
    • Searchable by filename and content
    • Preserves original files unchanged

NAMING PATTERN:
    YYYY-MM-DD_project_summary-keywords_sessionID8.jsonl
    
EXAMPLES OF GENERATED NAMES:
    2025-07-14_icici_data-analysis_1db5a5c2.jsonl
    2025-07-05_bank-nifty_options-backtesting_54f1b9b6.jsonl
    2025-07-14_Work_dashboard-comparison_c5160d2d.jsonl
EOF
            ;;
        *)
            echo "Unknown command: $1"
            echo "Use 'help' for usage information."
            exit 1
            ;;
    esac
}

# Check dependencies
if ! command -v jq >/dev/null 2>&1; then
    warn "jq is required but not installed. Install with: brew install jq"
    exit 1
fi

main "$@"