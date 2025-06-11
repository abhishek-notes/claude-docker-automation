#!/bin/bash

# Docker entrypoint with persistent configuration support
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🐳 Claude Docker Environment (Persistent Config)${NC}"
echo "================================================"

# Setup git
git config --global init.defaultBranch main
git config --global user.name "${GIT_USER_NAME:-Claude Bot}"
git config --global user.email "${GIT_USER_EMAIL:-claude@automation.local}"
git config --global --add safe.directory '*'

# Setup persistent configuration
setup_persistent_config() {
    echo -e "${GREEN}Setting up persistent configuration...${NC}"
    
    # Create base directories
    mkdir -p /home/claude/.claude
    mkdir -p /home/claude/.anthropic
    mkdir -p /home/claude/.config/claude-code
    
    # If we have persistent volume mounted
    if [ -d "/home/claude/.claude-persistent" ]; then
        echo -e "${GREEN}✓ Found persistent volume${NC}"
        
        # Initialize persistent directories if needed
        mkdir -p /home/claude/.claude-persistent/.claude
        mkdir -p /home/claude/.claude-persistent/.config
        mkdir -p /home/claude/.claude-persistent/.anthropic
        
        # Pre-configure Claude if this is first run
        if [ ! -f "/home/claude/.claude-persistent/.claude/settings.json" ]; then
            echo -e "${YELLOW}First run - creating default configuration...${NC}"
            
            cat > /home/claude/.claude-persistent/.claude/settings.json << 'EOF'
{
  "setupComplete": true,
  "firstRun": false,
  "hasShownWelcome": true,
  "hasCompletedOnboarding": true,
  "telemetryEnabled": false,
  "theme": "dark",
  "editor": {
    "theme": "dark",
    "fontSize": 14,
    "fontFamily": "Menlo, Monaco, 'Courier New', monospace"
  },
  "terminal": {
    "fontSize": 14
  }
}
EOF
            
            # Also create a state file that Claude might check
            cat > /home/claude/.claude-persistent/.claude/state.json << 'EOF'
{
  "version": "1.0.0",
  "setupComplete": true,
  "onboardingComplete": true,
  "lastUsed": "2024-01-01T00:00:00.000Z"
}
EOF
            
            # Create preferences
            cat > /home/claude/.claude-persistent/.claude/preferences.json << 'EOF'
{
  "theme": "dark",
  "setupComplete": true,
  "skipWelcome": true,
  "skipOnboarding": true,
  "agreedToTerms": true,
  "analyticsEnabled": false
}
EOF
        fi
        
        # Link persistent directories
        rm -rf /home/claude/.claude
        ln -s /home/claude/.claude-persistent/.claude /home/claude/.claude
        
        rm -rf /home/claude/.config
        ln -s /home/claude/.claude-persistent/.config /home/claude/.config
        
        # Handle authentication
        if [ -f "/home/claude/.claude.json.host" ]; then
            if [ ! -f "/home/claude/.claude-persistent/.claude.json" ]; then
                echo -e "${GREEN}✓ Copying authentication to persistent storage${NC}"
                cp /home/claude/.claude.json.host /home/claude/.claude-persistent/.claude.json
                chmod 600 /home/claude/.claude-persistent/.claude.json
            fi
            ln -sf /home/claude/.claude-persistent/.claude.json /home/claude/.claude.json
        elif [ -f "/home/claude/.claude-persistent/.claude.json" ]; then
            echo -e "${GREEN}✓ Using existing authentication${NC}"
            ln -sf /home/claude/.claude-persistent/.claude.json /home/claude/.claude.json
        fi
        
        # Set permissions
        chmod -R 700 /home/claude/.claude-persistent/.claude
        chmod -R 700 /home/claude/.claude-persistent/.config
        
    else
        echo -e "${YELLOW}⚠ No persistent volume - configuration will not be saved${NC}"
        
        # Still create default config for this session
        cat > /home/claude/.claude/settings.json << 'EOF'
{
  "setupComplete": true,
  "firstRun": false,
  "hasShownWelcome": true,
  "telemetryEnabled": false,
  "theme": "dark"
}
EOF
    fi
}

# Main setup
setup_persistent_config

# Handle GitHub token
if [ -n "$GITHUB_TOKEN" ]; then
    echo -e "${GREEN}✓ GitHub token configured${NC}"
    echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null || true
fi

# Change to workspace
cd /workspace 2>/dev/null || cd /home/claude

echo ""
echo -e "${GREEN}🚀 Persistent environment ready!${NC}"
echo -e "${GREEN}✓ Configuration will persist between runs${NC}"
echo ""

# Execute command
exec "$@"