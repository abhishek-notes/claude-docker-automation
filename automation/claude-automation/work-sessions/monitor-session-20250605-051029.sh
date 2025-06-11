#!/bin/bash
echo "📊 Monitoring Session: session-20250605-051029"
echo "================================"
echo ""

# Function to check file updates
check_file() {
    if [[ -f "$1" ]]; then
        echo "📄 $1 - Last updated: $(stat -f "%Sm" "$1" 2>/dev/null || stat -c "%y" "$1" 2>/dev/null || echo "Unknown")"
    else
        echo "⏳ $1 - Not created yet"
    fi
}

cd "/Users/abhishek/Work/claude-automation"

while true; do
    clear
    echo "📊 Session Monitor: session-20250605-051029"
    echo "Time: $(date)"
    echo "================================"
    echo ""
    
    check_file "PROGRESS.md"
    check_file "SUMMARY.md"
    check_file "ISSUES.md"
    
    echo ""
    echo "📁 Recent files:"
    ls -lt | head -5
    
    echo ""
    echo "Press Ctrl+C to stop monitoring"
    
    sleep 30
done
