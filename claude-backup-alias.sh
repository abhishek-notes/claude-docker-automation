#!/bin/bash

# Claude Backup Alias Script
# Provides convenient shortcuts for conversation backup management

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-help}" in
    "backup"|"b")
        "$SCRIPT_DIR/conversation-backup.sh" backup
        ;;
    "status"|"s")
        "$SCRIPT_DIR/conversation-backup.sh" status
        ;;
    "restore"|"r")
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 restore <session-id>"
            exit 1
        fi
        "$SCRIPT_DIR/conversation-backup.sh" restore "$2"
        ;;
    "list"|"l")
        echo "Recent conversations:"
        ls -lt ~/.claude-docker-conversations/conversations/*.jsonl 2>/dev/null | head -10 | while read -r line; do
            filename=$(echo "$line" | awk '{print $NF}')
            session_id=$(basename "$filename" .jsonl)
            timestamp=$(echo "$line" | awk '{print $6, $7, $8}')
            size=$(echo "$line" | awk '{print $5}')
            echo "  $session_id ($timestamp, $size bytes)"
        done || echo "No conversations found"
        ;;
    "find"|"f")
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 find <search-term>"
            exit 1
        fi
        echo "Searching conversations for: $2"
        grep -l "$2" ~/.claude-docker-conversations/conversations/*.jsonl 2>/dev/null | while read -r file; do
            session_id=$(basename "$file" .jsonl)
            echo "  Found in: $session_id"
        done || echo "No matches found"
        ;;
    "monitor"|"m")
        "$SCRIPT_DIR/conversation-monitor.sh" "${2:-status}"
        ;;
    "realtime"|"rt")
        "$SCRIPT_DIR/manual-realtime-backup.sh"
        ;;
    "periodic"|"p")
        "$SCRIPT_DIR/start-periodic-backup.sh" "${2:-status}"
        ;;
    "rename"|"rn")
        "$SCRIPT_DIR/conversation-renamer.sh" rename
        ;;
    "named"|"n")
        "$SCRIPT_DIR/conversation-renamer.sh" list
        ;;
    "search-named"|"sn")
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 search-named <search-term>"
            exit 1
        fi
        "$SCRIPT_DIR/conversation-renamer.sh" search "$2"
        ;;
    "work"|"w")
        if [ -d "/Users/abhishek/Work/claude-conversations" ]; then
            echo "📁 Work Conversations Directory:"
            echo "   /Users/abhishek/Work/claude-conversations/"
            echo ""
            echo "📊 Summary:"
            echo "   💾 Total: $(ls "/Users/abhishek/Work/claude-conversations/conversations"/*.jsonl 2>/dev/null | wc -l | tr -d ' ') conversations"
            for topic in trading development salesforce wordpress infrastructure data-analysis general; do
                count=$(ls "/Users/abhishek/Work/claude-conversations/by-topic/$topic"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
                if [ "$count" -gt 0 ]; then
                    echo "   • $topic: $count conversations"
                fi
            done
            echo ""
            echo "💡 To access in Claude: 'Claude, read claude-conversations/conversations/FILENAME.jsonl'"
        else
            echo "⚠️  Work conversations not set up yet. Run: ./manual-realtime-backup.sh"
        fi
        ;;
    "claude-guide"|"guide")
        if [ -f "/Users/abhishek/Work/claude-conversations/HOW_TO_USE_WITH_CLAUDE.md" ]; then
            echo "📚 Opening Claude usage guide..."
            open "/Users/abhishek/Work/claude-conversations/HOW_TO_USE_WITH_CLAUDE.md"
        else
            echo "⚠️  Guide not found. Run backup first to create it."
        fi
        ;;
    "help"|"h")
        cat << 'EOF'
Claude Conversation Backup Aliases

USAGE:
    ./claude-backup-alias.sh <command> [args]

COMMANDS:
    backup, b               Backup all conversations
    status, s               Show backup status
    restore, r <id>         Restore conversation by ID
    list, l                 List recent conversations (UUID format)
    find, f <term>          Search conversations for term
    monitor, m [cmd]        Manage real-time monitoring (start/stop/status)
    realtime, rt            Manual real-time backup (run while working)
    periodic, p [cmd]       Periodic backup every 30s (start/stop/status)
    rename, rn              Create meaningful names for all conversations  
    named, n                List conversations with meaningful names
    search-named, sn <term> Search conversations with meaningful names
    work, w                 Show Work directory conversations (for Claude access)
    claude-guide, guide     Open guide for using conversations in Claude
    help, h                 Show this help

EXAMPLES:
    ./claude-backup-alias.sh backup         # Backup all conversations
    ./claude-backup-alias.sh status         # Show status
    ./claude-backup-alias.sh realtime       # Backup current conversation now
    ./claude-backup-alias.sh periodic start # Start 30s periodic backup
    ./claude-backup-alias.sh rename         # Create readable names for conversations
    ./claude-backup-alias.sh named          # Show conversations with readable names
    ./claude-backup-alias.sh search-named "icici"    # Find ICICI conversations
    ./claude-backup-alias.sh work           # Show Work directory status for Claude access
    ./claude-backup-alias.sh claude-guide   # Open guide for using conversations in Claude
EOF
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use 'help' for usage information."
        exit 1
        ;;
esac