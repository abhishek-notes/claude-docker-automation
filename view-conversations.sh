#!/bin/bash

# Easy conversation viewer for Mac
# Shows your Claude conversations in readable format

EXPORTS_DIR="/Users/abhishek/Work/claude-conversations-exports"
PARSER_SCRIPT="/Users/abhishek/Work/claude-docker-automation/parse-conversations.js"

echo "🗣️ Claude Conversation Viewer"
echo "=============================="
echo ""

if [ ! -d "$EXPORTS_DIR" ]; then
    echo "❌ Conversation exports directory not found: $EXPORTS_DIR"
    exit 1
fi

# Count conversations
CONVERSATION_COUNT=$(find "$EXPORTS_DIR" -name "*.jsonl" | wc -l | tr -d ' ')
echo "📊 Found $CONVERSATION_COUNT conversation files"
echo ""

# List conversations with sizes and dates
echo "📂 Available conversations:"
echo "Size    Date       Time     Filename"
echo "----    ----       ----     --------"

find "$EXPORTS_DIR" -name "*.jsonl" -exec ls -lh {} \; | \
    sort -k6,7 -r | \
    awk '{
        size = $5
        date = $6 " " $7 " " $8
        filename = $9
        gsub(".*/", "", filename)
        printf "%-7s %-18s %s\n", size, date, filename
    }' | head -20

echo ""
echo "🔍 How to view conversations:"
echo "1. Copy a filename from above"
echo "2. Run: node $PARSER_SCRIPT $EXPORTS_DIR/<filename>"
echo ""
echo "📖 Example commands:"
echo "   # View a specific conversation"
echo "   node $PARSER_SCRIPT $EXPORTS_DIR/046b5ee1-06f4-40d8-aabf-1ea30990a91c.jsonl"
echo ""
echo "   # View the largest conversation"
LARGEST=$(find "$EXPORTS_DIR" -name "*.jsonl" -exec ls -lh {} \; | sort -k5 -hr | head -1 | awk '{print $9}')
if [ -n "$LARGEST" ]; then
    echo "   node $PARSER_SCRIPT $LARGEST"
fi
echo ""
echo "   # View the most recent conversation"
RECENT=$(find "$EXPORTS_DIR" -name "*.jsonl" -exec ls -lt {} \; | head -1 | awk '{print $9}')
if [ -n "$RECENT" ]; then
    echo "   node $PARSER_SCRIPT $RECENT"
fi

echo ""
echo "🍎 Mac Finder Integration:"
echo "   # Open folder in Finder"
echo "   open $EXPORTS_DIR"
echo ""
echo "   # Search conversations with Spotlight"
echo "   mdfind -onlyin $EXPORTS_DIR 'kind:jsonl'"

echo ""
echo "💡 Tips:"
echo "   • Larger files = longer conversations"
echo "   • Files are named with session IDs"
echo "   • Recent files likely contain current work"