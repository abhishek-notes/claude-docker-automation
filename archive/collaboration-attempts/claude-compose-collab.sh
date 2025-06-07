#!/bin/bash

# Claude Docker Compose Collaboration Launcher
# Simple way to start collaborative Claude instances
set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Setup collaboration structure in volume
setup_collab_volume() {
    echo -e "${BLUE}Setting up collaboration structure...${NC}"
    
    # Create a temporary container to setup the volume
    docker run --rm \
        -v claude-collaboration:/collab \
        busybox \
        sh -c 'mkdir -p /collab/alice /collab/bob /collab/shared && \
               echo "# Collaboration Space" > /collab/README.md && \
               echo "Alice and Bob can share files here" > /collab/shared/README.md'
    
    # Create collaboration protocol
    docker run --rm \
        -v claude-collaboration:/collab \
        busybox \
        sh -c 'cat > /collab/shared/collaboration-protocol.md << "EOF"
# Collaboration Protocol

## Communication
- Alice workspace: /collab/alice/
- Bob workspace: /collab/bob/
- Shared files: /collab/shared/

## For Alice (Backend)
- Write findings to: /collab/alice/findings.md
- Questions for Bob: /collab/alice/questions-for-bob.md
- Check Bob questions: /collab/bob/questions-for-alice.md

## For Bob (Frontend)
- Write findings to: /collab/bob/findings.md
- Questions for Alice: /collab/bob/questions-for-alice.md
- Check Alice questions: /collab/alice/questions-for-bob.md

## Sharing Code
cp important-file.js /collab/shared/
EOF'
}

# Start collaboration
start_collab() {
    local project_path="${1:-$(pwd)}"
    
    export PROJECT_PATH="$project_path"
    
    echo -e "${GREEN}Starting Claude Collaboration System${NC}"
    echo "Project: $project_path"
    echo ""
    
    # Setup volumes
    setup_collab_volume
    
    # Start services
    docker-compose -f docker-compose-collab.yml up -d claude-alice claude-bob
    
    echo ""
    echo -e "${GREEN}✓ Collaboration system started!${NC}"
    echo ""
    echo -e "${YELLOW}Quick Start Instructions:${NC}"
    echo ""
    echo "1. Open Alice's terminal:"
    echo "   docker attach claude-alice-backend"
    echo ""
    echo "2. Open Bob's terminal:"
    echo "   docker attach claude-bob-frontend"
    echo ""
    echo "3. In each terminal, start Claude:"
    echo "   claude --dangerously-skip-permissions"
    echo ""
    echo "4. Copy and paste the appropriate prompt:"
    echo ""
    
    # Show prompts
    ./claude-manual-collab.sh prompts
    
    echo ""
    echo -e "${BLUE}Other Commands:${NC}"
    echo "Monitor collaboration: docker-compose -f docker-compose-collab.yml --profile monitor up collab-monitor"
    echo "Stop collaboration: docker-compose -f docker-compose-collab.yml down"
    echo "View logs: docker-compose -f docker-compose-collab.yml logs"
}

# Stop collaboration
stop_collab() {
    echo -e "${YELLOW}Stopping collaboration...${NC}"
    docker-compose -f docker-compose-collab.yml down
    echo -e "${GREEN}✓ Collaboration stopped${NC}"
}

# Attach to instance
attach_to() {
    local instance="$1"
    case "$instance" in
        "alice")
            docker attach claude-alice-backend
            ;;
        "bob")
            docker attach claude-bob-frontend
            ;;
        *)
            echo "Usage: $0 attach [alice|bob]"
            ;;
    esac
}

# Main menu
case "${1:-help}" in
    "start")
        start_collab "${2:-}"
        ;;
    "stop")
        stop_collab
        ;;
    "attach")
        attach_to "${2:-}"
        ;;
    "monitor")
        docker-compose -f docker-compose-collab.yml --profile monitor up collab-monitor
        ;;
    "logs")
        docker-compose -f docker-compose-collab.yml logs -f
        ;;
    *)
        echo "Claude Docker Compose Collaboration"
        echo ""
        echo "Usage:"
        echo "  $0 start [project-path]  - Start collaboration"
        echo "  $0 stop                  - Stop collaboration"
        echo "  $0 attach [alice|bob]    - Attach to instance"
        echo "  $0 monitor               - Monitor collaboration"
        echo "  $0 logs                  - View logs"
        echo ""
        echo "Example:"
        echo "  $0 start /path/to/project"
        echo "  # Then in separate terminals:"
        echo "  $0 attach alice"
        echo "  $0 attach bob"
        ;;
esac