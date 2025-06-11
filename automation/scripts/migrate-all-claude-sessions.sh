#!/bin/bash

# Script to attach all existing Claude Docker sessions to tmux windows
# Shows last 2000 lines to help identify each session

TMUX_SESSION="claude-main"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔄 Migrating Existing Claude Sessions to tmux${NC}"
echo ""

# Create tmux session if it doesn't exist
if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "Creating new tmux session: $TMUX_SESSION"
    tmux new-session -d -s "$TMUX_SESSION" -n "dashboard"
    
    # Add dashboard
    tmux send-keys -t "$TMUX_SESSION:dashboard" \
        "watch -n 2 'echo \"🤖 Claude Docker Sessions\"; echo \"\"; docker ps --filter name=claude --format \"table {{.Names}}\t{{.Status}}\" | head -20'" Enter
fi

# Get all running Claude containers
containers=$(docker ps --filter "name=claude" --format "{{.Names}}" | grep -E "(claude-session|claude-alice|claude-bob)")

if [ -z "$containers" ]; then
    echo -e "${YELLOW}No running Claude containers found.${NC}"
    exit 0
fi

echo -e "${GREEN}Found $(echo "$containers" | wc -l) running Claude sessions${NC}"
echo ""

# Process each container
for container in $containers; do
    echo -e "${BLUE}Processing: $container${NC}"
    
    # Extract meaningful name
    if [[ $container == *"palladio"* ]]; then
        window_name="palladio-$(echo $container | grep -o '[0-9]\{6\}$')"
        project_hint="Palladio Software Project"
    elif [[ $container == *"Work"* ]]; then
        window_name="work-$(echo $container | grep -o '[0-9]\{6\}$')"
        project_hint="General Work Directory"
    elif [[ $container == *"automation"* ]]; then
        window_name="automation-$(echo $container | grep -o '[0-9]\{6\}$')"
        project_hint="Docker Automation Project"
    elif [[ $container == "claude-alice" ]] || [[ $container == "claude-bob" ]]; then
        window_name="$container"
        project_hint="Collaboration Bot"
    else
        window_name="$(echo $container | cut -d'-' -f3-4)"
        project_hint="Unknown Project"
    fi
    
    # Get last 2000 lines of logs to identify the session
    echo "  Analyzing session content..."
    
    # Create a temporary file with session info
    temp_file="/tmp/claude_session_${container}.txt"
    {
        echo "=== SESSION INFORMATION ==="
        echo "Container: $container"
        echo "Project Type: $project_hint"
        echo "Started: $(docker inspect -f '{{.State.StartedAt}}' $container 2>/dev/null | cut -d'T' -f1,2)"
        echo ""
        echo "=== RECENT ACTIVITY (Last 2000 lines) ==="
        echo ""
        docker logs --tail 2000 "$container" 2>&1 | \
            grep -E "(Working on|Created|Modified|cd |pwd|git |npm |Task:|TASK:|TODO:|Error:|Success:|✅|❌|📁|🚀|Starting|Completed)" | \
            tail -100
    } > "$temp_file"
    
    # Show summary
    echo -e "  ${GREEN}Summary:${NC}"
    grep -E "(Working on|cd |Task:|TASK:)" "$temp_file" | tail -5 | sed 's/^/    /'
    
    # Create tmux window
    echo "  Creating tmux window: $window_name"
    
    tmux new-window -t "$TMUX_SESSION" -n "$window_name" \
        "echo -e '${BLUE}=== Claude Session: $container ===${NC}'; \
         echo -e '${YELLOW}Project: $project_hint${NC}'; \
         echo ''; \
         echo 'Recent activity summary:'; \
         cat '$temp_file' | head -20; \
         echo ''; \
         echo -e '${GREEN}Press Enter to attach to this session...${NC}'; \
         echo -e '${YELLOW}Use Ctrl-p Ctrl-q to detach safely${NC}'; \
         read -n 1; \
         docker attach '$container'; \
         echo ''; \
         echo 'Session detached. Press any key to close...'; \
         read -n 1; \
         rm -f '$temp_file'"
    
    echo -e "  ${GREEN}✓ Added to tmux${NC}"
    echo ""
done

echo -e "${GREEN}✅ Migration complete!${NC}"
echo ""
echo -e "${BLUE}To access your sessions:${NC}"
echo "  1. Run: ${YELLOW}tmux attach -t $TMUX_SESSION${NC}"
echo "     Or use alias: ${YELLOW}ca${NC}"
echo ""
echo "  2. Navigate between windows:"
echo "     ${YELLOW}Ctrl-b w${NC} - Show window list"
echo "     ${YELLOW}Ctrl-b n${NC} - Next window"
echo "     ${YELLOW}Ctrl-b p${NC} - Previous window"
echo "     ${YELLOW}Ctrl-b [number]${NC} - Jump to window"
echo ""
echo "  3. Detach from tmux (leave everything running):"
echo "     ${YELLOW}Ctrl-b d${NC}"
echo ""
echo -e "${GREEN}Opening iTerm2 with tmux session...${NC}"

# Open iTerm2 and attach to tmux
osascript << EOF
tell application "iTerm"
    activate
    
    -- Create new window
    create window with default profile
    
    tell current session of current window
        write text "tmux attach -t $TMUX_SESSION"
    end tell
end tell
EOF