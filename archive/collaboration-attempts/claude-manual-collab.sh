#!/bin/bash

# Claude Manual Collaboration System
# Handles the fact that Claude needs manual input at startup
set -euo pipefail

DOCKER_IMAGE="claude-automation:latest"
COLLAB_DIR="/tmp/claude-collaboration-manual"
SESSION_NAME="claude-collab-$(date +%Y%m%d-%H%M%S)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Setup collaboration directory
setup_collab_dir() {
    mkdir -p "$COLLAB_DIR"/{alice,bob,shared}
    
    # Create initial collaboration instructions
    cat > "$COLLAB_DIR/shared/collaboration-protocol.md" << 'EOF'
# Collaboration Protocol

## For Alice (Backend Analyst)
- Write your findings to: /collab/alice/findings.md
- Check Bob's questions at: /collab/bob/questions-for-alice.md
- Answer Bob's questions in: /collab/alice/answers-for-bob.md

## For Bob (Frontend Specialist)
- Write your findings to: /collab/bob/findings.md
- Check Alice's questions at: /collab/alice/questions-for-bob.md
- Answer Alice's questions in: /collab/bob/answers-for-alice.md

## Collaboration Commands
- To ask the other Claude a question:
  echo "Your question here" >> /collab/[your-name]/questions-for-[other].md
  
- To check for questions:
  cat /collab/[other]/questions-for-[your-name].md
  
- To share code or findings:
  cp your-file.js /collab/shared/
EOF
}

# Start collaborative session with tmux
start_collab_tmux() {
    setup_collab_dir
    
    echo -e "${BLUE}Starting Claude Collaboration with tmux...${NC}"
    
    # Kill existing session if it exists
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    
    # Create new tmux session with Alice
    tmux new-session -d -s "$SESSION_NAME" -n "Alice-Backend" \
        "docker run -it --rm \
            --name claude-collab-alice \
            -v $COLLAB_DIR:/collab \
            -v $(pwd):/workspace \
            -w /workspace \
            $DOCKER_IMAGE \
            bash -c 'echo \"Claude Alice (Backend Analyst) ready. Collaboration directory: /collab\"; bash'"
    
    # Create Bob window
    tmux new-window -t "$SESSION_NAME" -n "Bob-Frontend" \
        "docker run -it --rm \
            --name claude-collab-bob \
            -v $COLLAB_DIR:/collab \
            -v $(pwd):/workspace \
            -w /workspace \
            $DOCKER_IMAGE \
            bash -c 'echo \"Claude Bob (Frontend Specialist) ready. Collaboration directory: /collab\"; bash'"
    
    # Create monitoring window
    tmux new-window -t "$SESSION_NAME" -n "Monitor" \
        "watch -n 2 'echo \"=== Collaboration Monitor ===\"; \
        echo \"\"; \
        echo \"Alice findings:\"; \
        tail -5 $COLLAB_DIR/alice/findings.md 2>/dev/null || echo \"No findings yet\"; \
        echo \"\"; \
        echo \"Bob findings:\"; \
        tail -5 $COLLAB_DIR/bob/findings.md 2>/dev/null || echo \"No findings yet\"; \
        echo \"\"; \
        echo \"Shared files:\"; \
        ls -la $COLLAB_DIR/shared/ 2>/dev/null | tail -5'"
    
    # Attach to session
    echo -e "${GREEN}Tmux session created!${NC}"
    echo ""
    echo -e "${YELLOW}Instructions:${NC}"
    echo "1. You're now in a tmux session with 3 windows:"
    echo "   - Alice-Backend: Backend analyst Claude"
    echo "   - Bob-Frontend: Frontend specialist Claude"
    echo "   - Monitor: Live collaboration status"
    echo ""
    echo "2. Start Claude in each window:"
    echo "   In Alice window: claude --dangerously-skip-permissions"
    echo "   In Bob window: claude --dangerously-skip-permissions"
    echo ""
    echo "3. Give them their initial tasks:"
    echo "   For Alice: 'You are Alice, a backend analyst. Read /collab/shared/collaboration-protocol.md and analyze the backend code.'"
    echo "   For Bob: 'You are Bob, a frontend specialist. Read /collab/shared/collaboration-protocol.md and analyze the frontend code.'"
    echo ""
    echo "4. Switch between windows: Ctrl+b then window number (0,1,2)"
    echo "5. Detach from session: Ctrl+b then d"
    echo "6. Reattach later: tmux attach -t $SESSION_NAME"
    echo ""
    
    tmux attach -t "$SESSION_NAME"
}

# Alternative: Use multiple terminals
start_collab_terminals() {
    setup_collab_dir
    
    echo -e "${BLUE}Starting Claude Collaboration with separate terminals...${NC}"
    
    # Create startup scripts
    cat > "$COLLAB_DIR/start-alice.sh" << EOF
#!/bin/bash
docker run -it --rm \
    --name claude-collab-alice \
    -v $COLLAB_DIR:/collab \
    -v $(pwd):/workspace \
    -w /workspace \
    $DOCKER_IMAGE \
    bash -c 'echo "Claude Alice (Backend Analyst) ready."; echo "Run: claude --dangerously-skip-permissions"; echo "Then paste: You are Alice, a backend analyst. Read /collab/shared/collaboration-protocol.md"; bash'
EOF

    cat > "$COLLAB_DIR/start-bob.sh" << EOF
#!/bin/bash
docker run -it --rm \
    --name claude-collab-bob \
    -v $COLLAB_DIR:/collab \
    -v $(pwd):/workspace \
    -w /workspace \
    $DOCKER_IMAGE \
    bash -c 'echo "Claude Bob (Frontend Specialist) ready."; echo "Run: claude --dangerously-skip-permissions"; echo "Then paste: You are Bob, a frontend specialist. Read /collab/shared/collaboration-protocol.md"; bash'
EOF

    chmod +x "$COLLAB_DIR/start-alice.sh" "$COLLAB_DIR/start-bob.sh"
    
    echo -e "${GREEN}Setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}Open 3 terminal windows and run:${NC}"
    echo "Terminal 1: $COLLAB_DIR/start-alice.sh"
    echo "Terminal 2: $COLLAB_DIR/start-bob.sh"
    echo "Terminal 3: watch -n 2 'ls -la $COLLAB_DIR/*/'"
    echo ""
    echo "In each Claude terminal:"
    echo "1. Run: claude --dangerously-skip-permissions"
    echo "2. For Alice paste: You are Alice, a backend analyst. Read /collab/shared/collaboration-protocol.md and analyze backend code."
    echo "3. For Bob paste: You are Bob, a frontend specialist. Read /collab/shared/collaboration-protocol.md and analyze frontend code."
}

# Simple prompts to copy/paste
show_prompts() {
    echo -e "${BLUE}Copy these prompts for each Claude:${NC}"
    echo ""
    echo -e "${GREEN}For Alice:${NC}"
    cat << 'EOF'
You are Alice, a backend analyst working collaboratively with Bob (frontend specialist). 

Your collaboration directory is /collab with this structure:
- /collab/alice/ - Your workspace
- /collab/bob/ - Bob's workspace  
- /collab/shared/ - Shared files

Tasks:
1. Analyze the backend code in /workspace
2. Document findings in /collab/alice/findings.md
3. Check /collab/bob/questions-for-alice.md periodically
4. Answer Bob's questions in /collab/alice/answers-for-bob.md
5. Ask Bob questions in /collab/alice/questions-for-bob.md

Start by reading /collab/shared/collaboration-protocol.md then analyzing the backend.
EOF
    
    echo ""
    echo -e "${GREEN}For Bob:${NC}"
    cat << 'EOF'
You are Bob, a frontend specialist working collaboratively with Alice (backend analyst).

Your collaboration directory is /collab with this structure:
- /collab/bob/ - Your workspace
- /collab/alice/ - Alice's workspace
- /collab/shared/ - Shared files

Tasks:
1. Analyze the frontend code in /workspace
2. Document findings in /collab/bob/findings.md
3. Check /collab/alice/questions-for-bob.md periodically
4. Answer Alice's questions in /collab/bob/answers-for-alice.md
5. Ask Alice questions in /collab/bob/questions-for-alice.md

Start by reading /collab/shared/collaboration-protocol.md then analyzing the frontend.
EOF
}

# Main menu
case "${1:-help}" in
    "tmux")
        start_collab_tmux
        ;;
    "terminals")
        start_collab_terminals
        ;;
    "prompts")
        show_prompts
        ;;
    "monitor")
        watch -n 2 "ls -la $COLLAB_DIR/*/"
        ;;
    *)
        echo "Claude Manual Collaboration System"
        echo ""
        echo "Usage:"
        echo "  $0 tmux       - Start with tmux (recommended)"
        echo "  $0 terminals  - Start with separate terminals"
        echo "  $0 prompts    - Show prompts to copy/paste"
        echo "  $0 monitor    - Monitor collaboration files"
        echo ""
        echo "This system handles Claude's need for manual input by:"
        echo "- Creating interactive Docker sessions"
        echo "- Providing prompts to copy/paste"
        echo "- Setting up shared directories for collaboration"
        ;;
esac