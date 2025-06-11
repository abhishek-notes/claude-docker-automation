#!/bin/bash

# Claude Max Master Orchestrator
# Your command center for autonomous coding

clear
echo "🎮 Claude Max Command Center"
echo "============================"
echo ""
echo "Quick Actions:"
echo ""
echo "1) Start 4-hour coding session"
echo "2) Start 8-hour coding session"
echo "3) Create new task file"
echo "4) Setup GitHub integration"
echo "5) Launch collaboration mode"
echo "6) View recent sessions"
echo "7) Open dashboard"
echo "8) Exit"
echo ""
read -p "Select action (1-8): " choice

case $choice in
    1)
        ./launch-work-session.sh 4
        ;;
    2)
        ./launch-work-session.sh 8
        ;;
    3)
        timestamp=$(date +%Y%m%d-%H%M%S)
        cp instructions/MASTER_TEMPLATE.md "instructions/task-$timestamp.md"
        ${EDITOR:-nano} "instructions/task-$timestamp.md"
        echo "Task file created: instructions/task-$timestamp.md"
        ;;
    4)
        ./setup-github-integration.sh
        ;;
    5)
        ./setup-collaboration.sh
        ;;
    6)
        echo "Recent sessions:"
        ls -lt logs/session-*.log | head -10
        ;;
    7)
        open dashboard/index.html
        ;;
    8)
        exit 0
        ;;
    *)
        echo "Invalid choice"
        ;;
esac
