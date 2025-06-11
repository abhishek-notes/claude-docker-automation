#!/bin/bash

# Claude Task Organization Helper

TMUX_SESSION="claude-main"

# Function to list windows organized by type
show_organized_windows() {
    echo -e "\033[1;36m🤖 Claude Sessions Organized by Type\033[0m"
    echo ""
    
    # Palladio projects
    echo -e "\033[1;34m🏛️  Palladio Projects:\033[0m"
    tmux list-windows -t "$TMUX_SESSION" 2>/dev/null | grep "palladio" | \
        awk '{print "    " $1 " " $2}' | sed 's/:/ -/' || echo "    None"
    
    # Work projects
    echo -e "\n\033[1;32m💼 Work Projects:\033[0m"
    tmux list-windows -t "$TMUX_SESSION" 2>/dev/null | grep "work" | \
        awk '{print "    " $1 " " $2}' | sed 's/:/ -/' || echo "    None"
    
    # Automation projects
    echo -e "\n\033[1;31m🤖 Automation Projects:\033[0m"
    tmux list-windows -t "$TMUX_SESSION" 2>/dev/null | grep "automation" | \
        awk '{print "    " $1 " " $2}' | sed 's/:/ -/' || echo "    None"
    
    # Other
    echo -e "\n\033[1;33m📁 Other:\033[0m"
    tmux list-windows -t "$TMUX_SESSION" 2>/dev/null | \
        grep -v -E "(palladio|work|automation|dashboard)" | \
        awk '{print "    " $1 " " $2}' | sed 's/:/ -/' || echo "    None"
    
    # Summary
    total=$(tmux list-windows -t "$TMUX_SESSION" 2>/dev/null | wc -l)
    echo -e "\n\033[1;36m📊 Total: $total windows\033[0m"
}

# Function to close completed sessions
cleanup_completed() {
    echo "Checking for completed sessions..."
    
    # Check each Docker container
    for container in $(docker ps --filter "name=claude-session" --format "{{.Names}}"); do
        # Check if SUMMARY.md exists (indicates completion)
        if docker exec "$container" test -f /workspace/SUMMARY.md 2>/dev/null; then
            echo "Found completed session: $container"
            read -p "Close this session? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Find and close the tmux window
                window_name=$(echo "$container" | sed 's/claude-session-//' | cut -d'-' -f1,2)
                tmux kill-window -t "$TMUX_SESSION:$window_name" 2>/dev/null
                echo "✅ Closed window: $window_name"
            fi
        fi
    done
}

# Function to create session groups
create_session_groups() {
    echo "Creating iTerm2 window arrangement for many sessions..."
    
    osascript << 'EOF'
tell application "iTerm"
    activate
    
    -- Get existing window or create new one
    if (count of windows) = 0 then
        create window with default profile
    end if
    
    tell current window
        -- Create a tab for Palladio projects
        create tab with profile "Palladio"
        tell current session
            write text "tmux attach -t claude-main \\; select-window -t 1"
            set name to "Palladio Projects"
        end tell
        
        -- Create a tab for Work projects  
        create tab with profile "Work"
        tell current session
            write text "tmux attach -t claude-main \\; select-window -t 1"
            set name to "Work Projects"
        end tell
        
        -- Create a tab for monitoring
        create tab with default profile
        tell current session
            write text "watch -n 2 docker ps --filter name=claude --format 'table {{.Names}}\t{{.Status}}'"
            set name to "Docker Monitor"
        end tell
    end tell
end tell
EOF
}

# Main menu
case "${1:-help}" in
    "organize"|"org")
        show_organized_windows
        ;;
    
    "cleanup")
        cleanup_completed
        ;;
    
    "groups")
        create_session_groups
        ;;
    
    "search")
        if [ -z "$2" ]; then
            echo "Usage: $0 search <pattern>"
            exit 1
        fi
        echo "Searching for windows matching: $2"
        tmux list-windows -t "$TMUX_SESSION" 2>/dev/null | grep -i "$2" || echo "No matches found"
        ;;
    
    *)
        echo "Claude Session Organization Helper"
        echo ""
        echo "Usage:"
        echo "  $0 organize  - Show windows organized by type"
        echo "  $0 cleanup   - Close completed sessions"
        echo "  $0 groups    - Create iTerm tab groups"
        echo "  $0 search    - Search for specific windows"
        echo ""
        echo "When you have many sessions:"
        echo "  1. Use 'organize' to see them grouped"
        echo "  2. Use 'cleanup' to close completed ones"
        echo "  3. Use Ctrl-b / in tmux to search"
        echo "  4. Name your tasks clearly when launching"
        ;;
esac