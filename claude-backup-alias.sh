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
    "help"|"h")
        cat << 'EOF'
Claude Conversation Backup Aliases

USAGE:
    ./claude-backup-alias.sh <command> [args]

COMMANDS:
    backup, b               Backup all conversations
    status, s               Show backup status
    restore, r <id>         Restore conversation by ID
    list, l                 List recent conversations
    find, f <term>          Search conversations for term
    monitor, m [cmd]        Manage real-time monitoring (start/stop/status)
    realtime, rt            Manual real-time backup (run while working)
    periodic, p [cmd]       Periodic backup every 30s (start/stop/status)
    help, h                 Show this help

EXAMPLES:
    ./claude-backup-alias.sh backup         # Backup all conversations
    ./claude-backup-alias.sh status         # Show status
    ./claude-backup-alias.sh realtime       # Backup current conversation now
    ./claude-backup-alias.sh periodic start # Start 30s periodic backup
    ./claude-backup-alias.sh find "dashboard"    # Find conversations about dashboard
EOF
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use 'help' for usage information."
        exit 1
        ;;
esac