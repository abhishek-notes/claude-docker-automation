#!/bin/bash

# Claude Authentication Setup for Docker
# Handles both API key and Claude Max authentication

echo "🔐 Claude Authentication Setup"
echo "=============================="
echo ""

# Check authentication options
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo "✅ API Key authentication configured"
    export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
else
    echo "📋 Authentication Options:"
    echo ""
    echo "Option 1: Use API Key"
    echo "  - Get your API key from: https://console.anthropic.com/"
    echo "  - Add to .env: export ANTHROPIC_API_KEY=\"your_key_here\""
    echo ""
    echo "Option 2: Use Claude Max Desktop Authentication"
    echo "  - Make sure you're logged into Claude Desktop"
    echo "  - Your session will inherit the authentication"
    echo ""
    
    read -p "Do you want to continue with Desktop authentication? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        echo "Please set up authentication and try again."
        exit 1
    fi
fi

echo ""
echo "🚀 Starting Claude with authentication..."

# Start Claude with proper authentication handling
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    # Use API key
    claude --dangerously-skip-permissions "$@"
else
    # Try desktop authentication
    echo "🔑 If prompted, use your Claude Max login credentials"
    claude --dangerously-skip-permissions "$@"
fi
