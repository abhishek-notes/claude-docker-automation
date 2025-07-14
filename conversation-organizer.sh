#!/bin/bash

# Conversation Organizer - Move conversations to Work directory for easy Claude access
# Makes your conversation history accessible to new Claude sessions

set -euo pipefail

BACKUP_DIR="$HOME/.claude-docker-conversations"
NAMED_DIR="$BACKUP_DIR/named-conversations"
WORK_CONVERSATIONS_DIR="/Users/abhishek/Work/claude-conversations"
WORK_INDEX_FILE="$WORK_CONVERSATIONS_DIR/INDEX.md"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN:${NC} $1"; }

# Create Work conversations directory structure
setup_work_directory() {
    log "📁 Setting up Work conversations directory..."
    
    mkdir -p "$WORK_CONVERSATIONS_DIR"/{conversations,by-topic,by-date}
    
    # Create main index
    cat > "$WORK_INDEX_FILE" << 'EOF'
# 📚 Claude Conversation Archive

This directory contains your organized Claude conversations, accessible to any new Claude session.

## 🎯 Quick Access for Claude

**To load a conversation in Claude, just reference it:**
```
Hey Claude, please read the conversation in "2025-07-14_ICICI_data-analysis_1db5a5c2.jsonl" 
and help me continue from where we left off.
```

## 📁 Directory Structure

### `/conversations/` - All conversations
All your conversations with meaningful names, sorted by date.

### `/by-topic/` - Organized by subject  
- `trading/` - Trading, backtesting, market analysis
- `development/` - Software development projects  
- `data-analysis/` - Data processing and analysis
- `infrastructure/` - Docker, system administration
- `wordpress/` - WordPress development
- `salesforce/` - Salesforce integration work

### `/by-date/` - Organized by timeframe
- `2025-07/` - July 2025 conversations
- `2025-06/` - June 2025 conversations  
- etc.

## 🔍 Quick Search

EOF

    log "✅ Work directory structure created"
}

# Improve conversation names with better extraction
improve_conversation_name() {
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
    
    # Extract working directory and task content for better context
    local task_content=$(grep -A5 -B5 '"content":".*CLAUDE_TASKS.md' "$jsonl_file" | head -20 2>/dev/null || echo "")
    local first_user_message=$(grep '"role":"user"' "$jsonl_file" | head -1 | jq -r '.message.content' 2>/dev/null | head -c 200 || echo "")
    
    # Determine project type and context
    local project_type=""
    local keywords=""
    
    # Check for specific project indicators
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
    elif echo "$task_content $first_user_message $summary" | grep -qi "palladio"; then
        project_type="Palladio"
        keywords="frontend-dev"
    elif echo "$task_content $first_user_message $summary" | grep -qi "docker"; then
        project_type="Docker"
        keywords="automation-system"
    else
        # Extract keywords from content
        keywords=$(echo "$task_content $first_user_message" | grep -oE '\b(dashboard|api|test|fix|analysis|data|automation|deployment|development|system)\b' | head -2 | tr '\n' '-' | sed 's/-$//' 2>/dev/null || echo "general")
        project_type="General"
    fi
    
    # Clean summary for filename
    local clean_summary=""
    if [ -n "$summary" ] && [ "$summary" != "null" ]; then
        clean_summary=$(echo "$summary" | sed 's/[^[:alnum:][:space:]-]//g' | tr ' ' '-' | tr -cd '[:alnum:]-' | cut -c1-40)
    fi
    
    # Build meaningful name
    local name_parts=()
    
    # Add timestamp
    if [ -n "$timestamp" ]; then
        name_parts+=("$timestamp")
    fi
    
    # Add project type
    if [ -n "$project_type" ]; then
        name_parts+=("$project_type")
    fi
    
    # Add summary or keywords
    if [ -n "$clean_summary" ]; then
        name_parts+=("$clean_summary")
    elif [ -n "$keywords" ]; then
        name_parts+=("$keywords")
    fi
    
    # Join parts and add session ID
    if [ ${#name_parts[@]} -gt 0 ]; then
        local result=$(IFS="_"; echo "${name_parts[*]}")
        result=$(echo "$result" | tr -cd '[:alnum:]_-' | sed 's/_{2,}/_/g' | sed 's/^_\|_$//g')
        echo "${result}_${session_id:0:8}"
    else
        echo "${session_id:0:8}_conversation"
    fi
}

# Determine topic category for organization
get_topic_category() {
    local filename="$1"
    local meta_file="$2"
    
    local content="$filename"
    if [ -f "$meta_file" ]; then
        content="$content $(cat "$meta_file")"
    fi
    
    if echo "$content" | grep -qi "icici\|bank.*nifty\|trading\|backtest\|flat.*trade\|tick.*data"; then
        echo "trading"
    elif echo "$content" | grep -qi "salesforce\|aralco"; then
        echo "salesforce"  
    elif echo "$content" | grep -qi "wordpress\|media.*upload\|blog"; then
        echo "wordpress"
    elif echo "$content" | grep -qi "palladio\|frontend\|navigation"; then
        echo "development"
    elif echo "$content" | grep -qi "docker\|container\|automation"; then
        echo "infrastructure"
    elif echo "$content" | grep -qi "data.*analysis\|processing"; then
        echo "data-analysis"
    else
        echo "general"
    fi
}

# Move and organize conversations
organize_conversations() {
    log "🚀 Organizing conversations in Work directory..."
    
    if [ ! -d "$NAMED_DIR" ]; then
        warn "No named conversations found. Run './claude-backup-alias.sh rename' first."
        return 1
    fi
    
    local moved_count=0
    local updated_index=""
    
    # Create topic directories
    mkdir -p "$WORK_CONVERSATIONS_DIR"/{by-topic/{trading,development,salesforce,wordpress,infrastructure,data-analysis,general},by-date}
    
    for jsonl_file in "$NAMED_DIR"/*.jsonl; do
        if [ ! -f "$jsonl_file" ]; then
            continue
        fi
        
        local original_name=$(basename "$jsonl_file")
        local session_id=$(echo "$original_name" | grep -o '[a-f0-9]\{8\}' | tail -1)
        local meta_file="${jsonl_file%.jsonl}.meta"
        
        # Improve the conversation name
        local improved_name=$(improve_conversation_name "$jsonl_file" "$session_id")
        local new_filename="${improved_name}.jsonl"
        
        # Copy to main conversations directory
        cp "$jsonl_file" "$WORK_CONVERSATIONS_DIR/conversations/$new_filename"
        
        # Copy metadata if exists
        if [ -f "$meta_file" ]; then
            cp "$meta_file" "$WORK_CONVERSATIONS_DIR/conversations/${improved_name}.meta"
        fi
        
        # Organize by topic
        local topic=$(get_topic_category "$improved_name" "$meta_file")
        cp "$jsonl_file" "$WORK_CONVERSATIONS_DIR/by-topic/$topic/$new_filename"
        
        # Organize by date
        local date_part=$(echo "$improved_name" | grep -o '^[0-9]\{4\}-[0-9]\{2\}')
        if [ -n "$date_part" ]; then
            local year_month="${date_part%-*}-${date_part#*-}"
            mkdir -p "$WORK_CONVERSATIONS_DIR/by-date/$year_month"
            cp "$jsonl_file" "$WORK_CONVERSATIONS_DIR/by-date/$year_month/$new_filename"
        fi
        
        # Add to index
        local summary=""
        if [ -f "$meta_file" ]; then
            summary=$(grep -A1 "# Summary" "$meta_file" | tail -1 2>/dev/null || echo "")
        fi
        
        updated_index="$updated_index
- **[$new_filename](conversations/$new_filename)** - $summary"
        
        ((moved_count++))
        log "📝 Organized: $new_filename → Topic: $topic"
    done
    
    # Update index file
    cat >> "$WORK_INDEX_FILE" << EOF

## 📋 All Conversations (${moved_count} total)
$updated_index

## 🎯 For Claude Sessions

**To continue a conversation:**
\`\`\`
Hey Claude, please read "conversations/YYYY-MM-DD_Project_description_sessionID.jsonl" 
and help me continue working on this project.
\`\`\`

**To get context from multiple conversations:**
\`\`\`
Claude, please review these conversations:
1. "conversations/2025-07-14_ICICI_data-analysis_1db5a5c2.jsonl"  
2. "conversations/2025-07-05_BankNifty_options-backtesting_54f1b9b6.jsonl"

Then help me understand the patterns and continue the work.
\`\`\`

## 📊 Topics Overview

- **Trading**: $(ls "$WORK_CONVERSATIONS_DIR/by-topic/trading"/*.jsonl 2>/dev/null | wc -l | tr -d ' ') conversations
- **Development**: $(ls "$WORK_CONVERSATIONS_DIR/by-topic/development"/*.jsonl 2>/dev/null | wc -l | tr -d ' ') conversations  
- **Data Analysis**: $(ls "$WORK_CONVERSATIONS_DIR/by-topic/data-analysis"/*.jsonl 2>/dev/null | wc -l | tr -d ' ') conversations
- **Infrastructure**: $(ls "$WORK_CONVERSATIONS_DIR/by-topic/infrastructure"/*.jsonl 2>/dev/null | wc -l | tr -d ' ') conversations
- **Salesforce**: $(ls "$WORK_CONVERSATIONS_DIR/by-topic/salesforce"/*.jsonl 2>/dev/null | wc -l | tr -d ' ') conversations
- **WordPress**: $(ls "$WORK_CONVERSATIONS_DIR/by-topic/wordpress"/*.jsonl 2>/dev/null | wc -l | tr -d ' ') conversations

Updated: $(date)
EOF
    
    log "✅ Organized $moved_count conversations in Work directory"
}

# Create Claude-readable conversation summaries
create_claude_summaries() {
    log "📄 Creating Claude-readable conversation summaries..."
    
    local summary_dir="$WORK_CONVERSATIONS_DIR/summaries"
    mkdir -p "$summary_dir"
    
    # Create topic summaries
    for topic in trading development salesforce wordpress infrastructure data-analysis; do
        local topic_dir="$WORK_CONVERSATIONS_DIR/by-topic/$topic"
        if [ -d "$topic_dir" ] && [ "$(ls "$topic_dir"/*.jsonl 2>/dev/null | wc -l)" -gt 0 ]; then
            
            local topic_title="${topic^}"
            local conversation_list=""
            local quick_list=""
            
            # Generate conversation lists
            if ls "$topic_dir"/*.jsonl >/dev/null 2>&1; then
                conversation_list=$(ls "$topic_dir"/*.jsonl | while read f; do
                    filename=$(basename "$f")
                    echo "- [$filename](../by-topic/$topic/$filename)"
                done)
                
                quick_list=$(ls "$topic_dir"/*.jsonl | head -5 | while read f; do
                    filename=$(basename "$f")
                    echo "- $filename"
                done)
            fi
            
            cat > "$summary_dir/${topic}-conversations.md" << EOF
# $topic_title Conversations Summary

## Quick Access for Claude

\`\`\`
Hey Claude, I have several $topic conversations. Here are the key ones:

$quick_list

Please read the most relevant one and help me continue the work.
\`\`\`

## All $topic_title Conversations

$conversation_list

## How to Use

1. **Continue specific conversation:**
   \`\`\`
   Claude, read "by-topic/$topic/CONVERSATION_FILE.jsonl" and continue from where we left off.
   \`\`\`

2. **Get overview of all $topic work:**
   \`\`\`
   Claude, review all conversations in the $topic folder and give me a summary of what we've accomplished.
   \`\`\`

Updated: $(date)
EOF
        fi
    done
    
    log "✅ Created Claude-readable summaries"
}

# Show how to access conversations from Claude
show_claude_access_guide() {
    log "📚 Claude Access Guide"
    echo ""
    echo -e "${BLUE}🎯 Your conversations are now in: ${NC}$WORK_CONVERSATIONS_DIR"
    echo ""
    echo -e "${BLUE}📋 To access in any new Claude session:${NC}"
    echo ""
    echo "1. **Continue your ICICI work:**"
    echo '   "Hey Claude, please read the conversation in "claude-conversations/conversations/2025-07-14_ICICI_data-analysis_1db5a5c2.jsonl" and help me continue the ICICI data analysis from where we left off."'
    echo ""
    echo "2. **Resume bank-nifty dashboard work:**"  
    echo '   "Claude, read "claude-conversations/conversations/2025-07-05_BankNifty_options-backtesting_54f1b9b6.jsonl" and help me continue building the bank-nifty options backtesting dashboard."'
    echo ""
    echo "3. **Get overview of all trading work:**"
    echo '   "Claude, review all conversations in claude-conversations/by-topic/trading/ and summarize our trading system development progress."'
    echo ""
    echo -e "${BLUE}📁 Directory structure:${NC}"
    echo "   $WORK_CONVERSATIONS_DIR/"
    echo "   ├── INDEX.md                    ← Start here"
    echo "   ├── conversations/              ← All conversations" 
    echo "   ├── by-topic/trading/           ← Trading conversations"
    echo "   ├── by-topic/development/       ← Development conversations"
    echo "   └── summaries/                  ← Claude-readable summaries"
    echo ""
}

# Main function
main() {
    case "${1:-help}" in
        "organize"|"o")
            setup_work_directory
            organize_conversations
            create_claude_summaries
            show_claude_access_guide
            ;;
        "status"|"s")
            if [ -d "$WORK_CONVERSATIONS_DIR" ]; then
                log "📊 Work Conversations Status"
                echo ""
                echo -e "${BLUE}📁 Location:${NC} $WORK_CONVERSATIONS_DIR"
                echo -e "${BLUE}💾 Total conversations:${NC} $(ls "$WORK_CONVERSATIONS_DIR/conversations"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')"
                echo ""
                echo -e "${BLUE}📋 By topic:${NC}"
                for topic in trading development salesforce wordpress infrastructure data-analysis general; do
                    local count=$(ls "$WORK_CONVERSATIONS_DIR/by-topic/$topic"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
                    if [ "$count" -gt 0 ]; then
                        echo "  • ${topic}: $count conversations"
                    fi
                done
            else
                warn "Work conversations not organized yet. Run 'organize' first."
            fi
            ;;
        "claude-guide"|"guide"|"g")
            show_claude_access_guide
            ;;
        "clean"|"c")
            if [ -d "$WORK_CONVERSATIONS_DIR" ]; then
                read -p "Remove all organized conversations from Work directory? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    rm -rf "$WORK_CONVERSATIONS_DIR"
                    log "🗑️  Cleaned up Work conversations directory"
                else
                    log "❌ Cleanup cancelled"
                fi
            else
                log "ℹ️  No Work conversations directory to clean"
            fi
            ;;
        "help"|"h")
            cat << 'EOF'
Conversation Organizer - Make conversations accessible to Claude

USAGE:
    ./conversation-organizer.sh <command>

COMMANDS:
    organize, o             Organize all conversations in Work directory
    status, s               Show organization status
    claude-guide, guide, g  Show how to access conversations from Claude
    clean, c                Remove organized conversations (keeps originals)
    help, h                 Show this help

FEATURES:
    • Moves conversations to /Users/abhishek/Work/claude-conversations/
    • Organizes by topic (trading, development, etc.)
    • Organizes by date (2025-07/, 2025-06/, etc.)  
    • Creates Claude-readable INDEX.md and summaries
    • Improves conversation names with better context
    • Makes conversations accessible to any new Claude session

WORKFLOW:
    1. ./conversation-organizer.sh organize    # Set up Work directory
    2. Start new Claude session in /Users/abhishek/Work/
    3. Say: "Claude, read claude-conversations/INDEX.md"
    4. Continue specific conversations as needed

EXAMPLE CLAUDE COMMANDS:
    "Hey Claude, read claude-conversations/conversations/2025-07-14_ICICI_data-analysis_1db5a5c2.jsonl"
    "Claude, review all trading conversations and summarize our progress"
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