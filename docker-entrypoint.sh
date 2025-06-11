#!/bin/bash

# Docker entrypoint for Claude Max authentication - Pre-configured
# Skips first-time setup and creates optimal environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🐳 Claude Code Docker Environment (Claude Max)${NC}"
echo "=============================================="
echo ""

# Check if we're in a workspace
if [ -d "/workspace" ]; then
    echo -e "${GREEN}✓ Workspace mounted${NC}"
    cd /workspace
else
    echo -e "${YELLOW}⚠  No workspace mounted, using default${NC}"
    cd /home/claude/workspace
fi

# Set up git configuration if provided
if [ -f "/tmp/.gitconfig" ]; then
    echo -e "${GREEN}✓ Git config found, applying...${NC}"
    cp /tmp/.gitconfig /home/claude/.gitconfig
fi

# Set git to use main as default branch and configure user
echo -e "${GREEN}✓ Setting git defaults${NC}"
git config --global init.defaultBranch main
git config --global user.name "${GIT_USER_NAME:-Claude Bot}"
git config --global user.email "${GIT_USER_EMAIL:-claude@automation.local}"
git config --global --add safe.directory '*'

# Set up Claude authentication directories
mkdir -p /home/claude/.claude
mkdir -p /home/claude/.anthropic

# Pre-configure Claude Code to skip setup prompts
echo -e "${GREEN}✓ Pre-configuring Claude Code...${NC}"

# Create settings to skip first-time setup
cat > /home/claude/.claude/settings.json << 'EOF'
{
  "theme": "dark",
  "setupComplete": true,
  "firstRun": false,
  "hasShownWelcome": true,
  "telemetryEnabled": false,
  "autoUpdate": false,
  "onboardingComplete": true,
  "agreedToTerms": true
}
EOF

# Create config to bypass setup
cat > /home/claude/.claude/config.json << 'EOF'
{
  "setupComplete": true,
  "firstTimeSetup": false,
  "theme": "dark",
  "analytics": false,
  "autoUpdate": false,
  "onboardingComplete": true
}
EOF

# Set permissions for config files
chmod 600 /home/claude/.claude/settings.json
chmod 600 /home/claude/.claude/config.json

# Handle Claude Max authentication - CREATE WRITABLE COPY
if [ -f "/home/claude/.claude.json.readonly" ]; then
    echo -e "${GREEN}✓ Creating writable copy of Claude Max authentication...${NC}"
    cp /home/claude/.claude.json.readonly /home/claude/.claude.json
    chmod 600 /home/claude/.claude.json
    echo -e "${GREEN}✓ Claude Max authentication ready${NC}"
elif [ -f "/home/claude/.claude.json" ]; then
    echo -e "${GREEN}✓ Claude Max authentication file found${NC}"
    chmod 600 /home/claude/.claude.json
else
    echo -e "${RED}✗ Claude Max authentication file not found${NC}"
    echo "Make sure you're logged into Claude Code on your Mac"
fi

# Copy Claude Code configuration if available
if [ -d "/home/claude/.claude-host" ]; then
    echo -e "${GREEN}✓ Copying Claude Code configuration...${NC}"
    # Copy settings but don't overwrite our pre-configured files
    cp /home/claude/.claude-host/*.toml /home/claude/.claude/ 2>/dev/null || true
    cp /home/claude/.claude-host/projects /home/claude/.claude/ 2>/dev/null || true
fi

# Set up GitHub token if provided
if [ -n "$GITHUB_TOKEN" ]; then
    echo -e "${GREEN}✓ GitHub token configured${NC}"
    echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null || true
fi

# Initialize git repository if not exists
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}📦 Initializing git repository with main branch...${NC}"
    git init --initial-branch=main
    git config user.name "${GIT_USER_NAME:-Claude Bot}"
    git config user.email "${GIT_USER_EMAIL:-claude@automation.local}"
else
    echo -e "${GREEN}✓ Git repository exists${NC}"
    # Check current branch and switch to main if needed
    current_branch=$(git branch --show-current 2>/dev/null || echo "")
    if [ -z "$current_branch" ]; then
        echo -e "${YELLOW}📦 Creating main branch...${NC}"
        git checkout -b main 2>/dev/null || true
    elif [ "$current_branch" = "master" ]; then
        echo -e "${YELLOW}📦 Switching from master to main...${NC}"
        git branch -m master main 2>/dev/null || true
    fi
fi

echo ""
echo -e "${GREEN}🚀 Claude Max environment ready!${NC}"
echo -e "${GREEN}✓ Setup prompts disabled${NC}"
echo -e "${GREEN}✓ Authentication configured${NC}"
echo ""

# If no command specified, start interactive bash
if [ "$#" -eq 0 ] || [ "$1" = "bash" ]; then
    echo -e "${BLUE}Starting interactive session...${NC}"
    echo "Commands available:"
    echo "  claude --dangerously-skip-permissions  # Start Claude (no setup prompts)"
    echo "  claude --version                       # Check Claude version"
    echo "  exit                                   # Exit container"
    echo ""
    exec bash
else
    # Execute the provided command
    exec "$@"
fi
