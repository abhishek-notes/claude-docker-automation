#!/bin/bash

# Claude Docker Automation Setup Script
# Complete setup for Docker-based Claude automation

set -euo pipefail

SETUP_DIR="/Users/abhishek/Work/claude-docker-automation"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}🐳 Claude Docker Automation Setup${NC}"
echo "=================================="
echo ""

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker not found${NC}"
        echo "Please install Docker Desktop for Mac from: https://docker.com/products/docker-desktop"
        exit 1
    else
        echo -e "${GREEN}✅ Docker found${NC}"
    fi
    
    # Check Docker daemon
    if ! docker info >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Docker daemon not running${NC}"
        echo "Please start Docker Desktop and try again"
        exit 1
    else
        echo -e "${GREEN}✅ Docker daemon running${NC}"
    fi
    
    # Check Claude Code
    if ! command -v claude >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Claude Code not found globally${NC}"
        echo "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code@latest
    else
        echo -e "${GREEN}✅ Claude Code found${NC}"
    fi
    
    echo ""
}

# Setup environment
setup_environment() {
    echo -e "${BLUE}Setting up environment...${NC}"
    
    cd "$SETUP_DIR"
    
    # Copy environment template
    if [ ! -f ".env" ]; then
        cp .env.example .env
        echo -e "${YELLOW}📝 Created .env file - please edit with your credentials${NC}"
    fi
    
    # Add aliases to shell
    if ! grep -q "claude-docker-automation" ~/.zshrc 2>/dev/null; then
        echo "" >> ~/.zshrc
        echo "# Claude Docker Automation" >> ~/.zshrc
        echo "source $SETUP_DIR/.env.example" >> ~/.zshrc
        echo -e "${GREEN}✅ Added aliases to ~/.zshrc${NC}"
    else
        echo -e "${GREEN}✅ Aliases already configured${NC}"
    fi
}

# Build Docker image
build_docker_image() {
    echo -e "${BLUE}Building Docker image...${NC}"
    
    cd "$SETUP_DIR"
    
    if docker build -t claude-automation:latest . ; then
        echo -e "${GREEN}✅ Docker image built successfully${NC}"
    else
        echo -e "${RED}❌ Failed to build Docker image${NC}"
        exit 1
    fi
    
    echo ""
}

# Test installation
test_installation() {
    echo -e "${BLUE}Testing installation...${NC}"
    
    cd "$SETUP_DIR"
    
    # Test Docker image
    if docker run --rm claude-automation:latest claude --version >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker image working${NC}"
    else
        echo -e "${RED}❌ Docker image test failed${NC}"
    fi
    
    # Test script
    if ./claude-docker.sh help >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Script executable${NC}"
    else
        echo -e "${RED}❌ Script not executable${NC}"
    fi
    
    echo ""
}

# Create example project
create_example() {
    echo -e "${BLUE}Creating example project...${NC}"
    
    local example_dir="$SETUP_DIR/example-project"
    mkdir -p "$example_dir"
    
    cat > "$example_dir/CLAUDE_TASKS.md" << 'EOF'
# Example Claude Automation Task

## Project Overview
- **Goal**: Create a simple Node.js application
- **Scope**: Basic Express server with API endpoints
- **Time Estimate**: 1 hour

## Tasks

### 1. Initialize Project
- **Description**: Set up Node.js project structure
- **Requirements**: package.json, basic folder structure
- **Acceptance Criteria**: Working npm project

### 2. Create Express Server
- **Description**: Basic Express.js server
- **Requirements**: 
  - GET /api/health endpoint
  - Basic error handling
  - Port configuration
- **Acceptance Criteria**: Server starts and responds to requests

### 3. Add Documentation
- **Description**: Create README and API docs
- **Requirements**: Installation and usage instructions
- **Acceptance Criteria**: Clear documentation

## Technical Requirements
- [ ] Use ES6+ syntax
- [ ] Include basic error handling
- [ ] Follow Node.js best practices
- [ ] Create meaningful commit messages

## Deliverables
- [ ] Working Express server
- [ ] API documentation
- [ ] PROGRESS.md with status updates
- [ ] SUMMARY.md with final results
EOF
    
    # Initialize git repo
    cd "$example_dir"
    git init
    git add CLAUDE_TASKS.md
    git commit -m "Initial commit: Add Claude tasks"
    
    echo -e "${GREEN}✅ Example project created at: $example_dir${NC}"
    echo ""
}

# Show completion message
show_completion() {
    echo -e "${GREEN}🎉 Setup Complete!${NC}"
    echo "=================="
    echo ""
    echo -e "${PURPLE}Quick Start Commands:${NC}"
    echo ""
    echo -e "${YELLOW}1. Edit your credentials:${NC}"
    echo "   nano $SETUP_DIR/.env"
    echo ""
    echo -e "${YELLOW}2. Start a session:${NC}"
    echo "   claude-start"
    echo "   # or"
    echo "   ./claude-docker.sh start"
    echo ""
    echo -e "${YELLOW}3. Try the example:${NC}"
    echo "   cd $SETUP_DIR/example-project"
    echo "   ../claude-docker.sh start . CLAUDE_TASKS.md 1"
    echo ""
    echo -e "${YELLOW}4. Open web interface:${NC}"
    echo "   claude-web"
    echo "   # or"
    echo "   ./claude-docker.sh web"
    echo ""
    echo -e "${PURPLE}Available Commands:${NC}"
    echo "  claude-start [path] [hours]  - Start new session"
    echo "  claude-list                  - List active sessions" 
    echo "  claude-attach                - Attach to session"
    echo "  claude-stop                  - Stop all sessions"
    echo "  claude-web                   - Start web interface"
    echo "  claude-quick [path] [hours]  - Quick 2-hour session"
    echo "  claude-long [path] [hours]   - Long 8-hour session"
    echo ""
    echo -e "${BLUE}📚 Documentation:${NC}"
    echo "  README.md - Complete guide"
    echo "  Web UI - http://localhost:3456"
    echo ""
    echo -e "${YELLOW}⚠️  Don't forget to:${NC}"
    echo "1. Add your ANTHROPIC_API_KEY to .env"
    echo "2. Add your GITHUB_TOKEN to .env (optional)"
    echo "3. Reload your shell: source ~/.zshrc"
    echo ""
    echo -e "${GREEN}Happy autonomous coding! 🚀${NC}"
}

# Main execution
main() {
    check_prerequisites
    setup_environment
    build_docker_image
    test_installation
    create_example
    show_completion
}

# Run setup
main "$@"
