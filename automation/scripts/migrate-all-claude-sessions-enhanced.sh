#!/bin/bash

# Enhanced migration script that sets iTerm profiles based on project type

TMUX_SESSION="claude-main"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔄 Migrating Existing Claude Sessions to tmux with iTerm Profiles${NC}"
echo ""

# Function to determine iTerm profile based on container name
get_iterm_profile() {
    local container="$1"
    if [[ $container == *"palladio"* ]]; then
        echo "Claude - Palladio"
    elif [[ $container == *"automation"* ]]; then
        echo "Claude - Automation"
    else
        echo "Claude - Work"
    fi
}

# Create tmux session if it doesn't exist
if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "Creating new tmux session: $TMUX_SESSION"
    tmux new-session -d -s "$TMUX_SESSION" -n "dashboard"
    
    # Add dashboard with color coding
    tmux send-keys -t "$TMUX_SESSION:dashboard" \
        "watch -n 2 'echo -e \"\\033[1;36m🤖 Claude Docker Sessions\\033[0m\"; echo \"\"; docker ps --filter name=claude --format \"table {{.Names}}\t{{.Status}}\" | head -20'" Enter
fi

# Get all running Claude containers
containers=$(docker ps --filter "name=claude" --format "{{.Names}}" | grep -E "(claude-session|claude-alice|claude-bob)")

if [ -z "$containers" ]; then
    echo -e "${YELLOW}No running Claude containers found.${NC}"
    exit 0
fi

echo -e "${GREEN}Found $(echo "$containers" | wc -l) running Claude sessions${NC}"
echo ""

# Create a summary file
summary_file="/tmp/claude_sessions_summary.txt"
> "$summary_file"

# Process each container
for container in $containers; do
    echo -e "${BLUE}Processing: $container${NC}"
    
    # Extract meaningful name and determine profile
    if [[ $container == *"palladio"* ]]; then
        window_name="palladio-$(echo $container | grep -o '[0-9]\{6\}$')"
        project_hint="🏛️ Palladio Software Project"
        profile="Palladio"
    elif [[ $container == *"Work"* ]]; then
        window_name="work-$(echo $container | grep -o '[0-9]\{6\}$')"
        project_hint="💼 General Work Directory"
        profile="Work"
    elif [[ $container == *"automation"* ]]; then
        window_name="automation-$(echo $container | grep -o '[0-9]\{6\}$')"
        project_hint="🤖 Docker Automation Project"
        profile="Automation"
    elif [[ $container == "claude-alice" ]] || [[ $container == "claude-bob" ]]; then
        window_name="$container"
        project_hint="👥 Collaboration Bot"
        profile="Work"
    else
        window_name="$(echo $container | cut -d'-' -f3-4)"
        project_hint="📁 Unknown Project"
        profile="Default"
    fi
    
    # Get session details
    echo "  Analyzing session content..."
    
    # Create a temporary file with session info
    temp_file="/tmp/claude_session_${container}.txt"
    {
        echo "=== SESSION INFORMATION ==="
        echo "Container: $container"
        echo "Project Type: $project_hint"
        echo "iTerm Profile: $profile"
        echo "Started: $(docker inspect -f '{{.State.StartedAt}}' $container 2>/dev/null | cut -d'T' -f1,2)"
        echo ""
        echo "=== WORKING DIRECTORY ==="
        docker exec "$container" pwd 2>/dev/null || echo "Unable to determine"
        echo ""
        echo "=== GIT STATUS ==="
        docker exec "$container" git status --short 2>/dev/null || echo "No git repository"
        echo ""
        echo "=== RECENT ACTIVITY (Last 100 meaningful lines from 10000) ==="
        echo ""
        docker logs --tail 10000 "$container" 2>&1 | \
            grep -E "(Working on|Created|Modified|cd |pwd|git |npm |Task:|TASK:|TODO:|Error:|Success:|✅|❌|📁|🚀|Starting|Completed|PROGRESS|SUMMARY)" | \
            tail -100
    } > "$temp_file"
    
    # Add to summary
    {
        echo "Window $window_name: $project_hint"
        echo "  Container: $container"
        echo "  Profile: $profile"
        docker logs --tail 10000 "$container" 2>&1 | grep -E "(Task:|TASK:|Working on)" | tail -1 | sed 's/^/  Last task: /'
        echo ""
    } >> "$summary_file"
    
    # Show summary
    echo -e "  ${GREEN}Summary:${NC}"
    grep -E "(Working on|Task:|TASK:|cd |git status|Current directory|Starting task)" "$temp_file" | tail -5 | sed 's/^/    /'
    
    # Create tmux window
    echo "  Creating tmux window: $window_name (Profile: $profile)"
    
    tmux new-window -t "$TMUX_SESSION" -n "$window_name" \
        "echo -e '${BLUE}=== Claude Session: $container ===${NC}'; \
         echo -e '${YELLOW}Project: $project_hint${NC}'; \
         echo -e 'iTerm Profile: $profile'; \
         echo ''; \
         echo 'Session Details:'; \
         cat '$temp_file' | head -100; \
         echo ''; \
         echo -e '${GREEN}Press Enter to attach to this session...${NC}'; \
         echo -e '${YELLOW}Use Ctrl-p Ctrl-q to detach safely${NC}'; \
         echo -e '${BLUE}Right-click → Change Profile → $profile for color coding${NC}'; \
         read -n 1; \
         docker attach '$container'; \
         echo ''; \
         echo -e '${GREEN}Session detached. This window will stay open.${NC}'; \
         echo -e '${YELLOW}Press Ctrl-b w to see all windows${NC}'; \
         echo -e '${BLUE}Press Enter to re-attach to Docker${NC}'; \
         while true; do \
             read -p 'Command (attach/new/exit): ' cmd; \
             case \$cmd in \
                 'attach'|'a'|'') docker attach '$container' ;; \
                 'new') break ;; \
                 'exit') exit ;; \
                 *) echo 'Options: attach (Enter), new, exit' ;; \
             esac; \
         done"
    
    echo -e "  ${GREEN}✓ Added to tmux${NC}"
    echo ""
done

echo -e "${GREEN}✅ Migration complete!${NC}"
echo ""
echo -e "${BLUE}Session Summary:${NC}"
cat "$summary_file"
echo ""
echo -e "${BLUE}To access your sessions:${NC}"
echo "  1. Run: ${YELLOW}tmux attach -t $TMUX_SESSION${NC}"
echo "     Or use alias: ${YELLOW}ca${NC}"
echo ""
echo "  2. Navigate between windows:"
echo "     ${YELLOW}Ctrl-b w${NC} - Show window list (best way!)"
echo "     ${YELLOW}Ctrl-b n${NC} - Next window"
echo "     ${YELLOW}Ctrl-b p${NC} - Previous window"
echo "     ${YELLOW}Ctrl-b [number]${NC} - Jump to window"
echo ""
echo "  3. To set colors for each window:"
echo "     Right-click → Change Profile → Select matching profile"
echo ""
echo "  4. Detach from tmux (leave everything running):"
echo "     ${YELLOW}Ctrl-b d${NC}"
echo ""

# Check if profiles exist
if ! grep -q "Palladio" ~/Library/Preferences/com.googlecode.iterm2.plist 2>/dev/null; then
    echo -e "${YELLOW}⚠️  iTerm profiles not found. Run:${NC}"
    echo "  ~/Work/setup-iterm-profiles.sh"
    echo "  Then manually create the profiles in iTerm preferences"
    echo ""
fi

echo -e "${GREEN}Opening iTerm2 with tmux session...${NC}"

# Open iTerm2 and attach to tmux
osascript << EOF
tell application "iTerm"
    activate
    
    -- Create new window
    create window with default profile
    
    tell current session of current window
        write text "tmux attach -t claude-main"
    end tell
end tell
EOF

rm -f "$summary_file"