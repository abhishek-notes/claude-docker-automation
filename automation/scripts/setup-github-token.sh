#!/bin/bash

# GitHub Token Setup for Claude Docker Automation
# This script helps you securely configure GitHub tokens for all Claude containers

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Token file location
TOKEN_FILE="/workspace/.env.github"

# Check if token file exists
if [ -f "$TOKEN_FILE" ]; then
    info "GitHub token file found at: $TOKEN_FILE"
    
    # Load and validate token
    source "$TOKEN_FILE"
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        # Mask token for display
        masked_token="${GITHUB_TOKEN:0:8}...${GITHUB_TOKEN: -4}"
        log "✓ GitHub token loaded: $masked_token"
        
        # Test token
        echo -e "${YELLOW}Testing GitHub token...${NC}"
        if gh auth status --hostname github.com 2>/dev/null; then
            log "✓ GitHub token is valid and authenticated"
        else
            # Try to authenticate
            echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null && {
                log "✓ GitHub CLI authenticated successfully"
            } || {
                error "Failed to authenticate with GitHub token"
                exit 1
            }
        fi
        
        # Export for Docker containers
        export GITHUB_TOKEN
        export GH_TOKEN="${GITHUB_TOKEN}"
        
        info "Token is ready for use in Claude Docker containers"
        echo ""
        echo "To use in your Docker containers, add these to your docker run command:"
        echo "  -e GITHUB_TOKEN=\$GITHUB_TOKEN"
        echo "  -e GH_TOKEN=\$GH_TOKEN"
        echo ""
        echo "Or source this file before running Docker:"
        echo "  source $TOKEN_FILE"
        echo ""
    else
        error "Token file exists but GITHUB_TOKEN is empty"
        exit 1
    fi
else
    error "GitHub token file not found at: $TOKEN_FILE"
    echo ""
    echo "Please create the file with your GitHub token:"
    echo ""
    echo "cat > $TOKEN_FILE << 'EOF'"
    echo "# GitHub Authentication"
    echo "GITHUB_TOKEN=your_github_token_here"
    echo "GH_TOKEN=your_github_token_here"
    echo "GITHUB_USERNAME=your_github_username"
    echo "EOF"
    echo ""
    echo "Make sure to:"
    echo "1. Replace 'your_github_token_here' with your actual token"
    echo "2. Replace 'your_github_username' with your GitHub username"
    echo "3. Keep this file secure and never commit it to Git"
    exit 1
fi

# Show how to use in different scenarios
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${BLUE}Usage Examples:${NC}"
echo ""
echo "1. Manual Docker run:"
echo "   source $TOKEN_FILE"
echo "   docker run -e GITHUB_TOKEN=\$GITHUB_TOKEN ..."
echo ""
echo "2. With claude-auto.sh:"
echo "   source $TOKEN_FILE"
echo "   ./claude-docker-automation/claude-auto.sh"
echo ""
echo "3. Add to your shell profile for persistence:"
echo "   echo 'source $TOKEN_FILE' >> ~/.bashrc"
echo ""
echo -e "${YELLOW}Security Notes:${NC}"
echo "• Token file is in .gitignore - won't be committed"
echo "• All Claude containers can access this token"
echo "• Token is loaded as environment variable"
echo "• Keep your token secure and rotate regularly"