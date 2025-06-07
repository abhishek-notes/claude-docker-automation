#!/bin/bash

# Install and configure MCP Smart Operations Server for Claude Desktop
set -e

echo "🔧 Installing MCP Smart Operations Server..."

# Check if we have Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js first."
    exit 1
fi

# Check if we have Claude Desktop
CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"
if [[ ! -d "$CLAUDE_CONFIG_DIR" ]]; then
    echo "❌ Claude Desktop not found. Please install Claude Desktop first."
    exit 1
fi

# Install required packages
echo "📦 Installing MCP SDK packages..."
npm install @modelcontextprotocol/sdk

# Create Claude Desktop config
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/claude_desktop_config.json"
echo "⚙️ Configuring Claude Desktop..."

# Backup existing config if it exists
if [[ -f "$CLAUDE_CONFIG_FILE" ]]; then
    cp "$CLAUDE_CONFIG_FILE" "$CLAUDE_CONFIG_FILE.backup.$(date +%Y%m%d-%H%M%S)"
    echo "📁 Backed up existing config"
fi

# Create or update config with SECURITY RESTRICTIONS
cat > "$CLAUDE_CONFIG_FILE" << EOF
{
  "mcpServers": {
    "smart-operations": {
      "command": "node",
      "args": ["/Users/abhishek/Work/claude-docker-automation/mcp-smart-ops.js"],
      "env": {
        "NODE_ENV": "production",
        "MCP_SECURITY_MODE": "host_only",
        "MCP_NO_CONTAINER_ACCESS": "true"
      }
    }
  },
  "security": {
    "restrictContainerAccess": true,
    "allowHostOperationsOnly": true,
    "note": "MCP server runs on HOST for safety features. Docker Claude has NO access to this."
  }
}
EOF

echo "✅ MCP Smart Operations Server installed and configured!"
echo ""
echo "📋 Next steps:"
echo "1. Restart Claude Desktop for changes to take effect"
echo "2. The smart operations server will provide:"
echo "   - Safe file deletion (moves to trash)"
echo "   - Versioned backups with git-like naming"
echo "   - Breaking change detection for APIs"
echo "   - Force operations without prompts"
echo "   - Full project snapshots"
echo ""
echo "🔧 Configuration file: $CLAUDE_CONFIG_FILE"
echo "📝 Server script: /Users/abhishek/Work/claude-docker-automation/mcp-smart-ops.js"
echo "📁 Backups stored in: /Users/abhishek/Work/claude-docker-automation/backups"