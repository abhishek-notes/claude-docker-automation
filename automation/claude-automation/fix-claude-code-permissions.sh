#!/bin/bash

# Fix Claude Code MCP and Permissions Setup

echo "🔧 Fixing Claude Code MCP Configuration..."

# Create config directories
mkdir -p ~/.config/claude-code
mkdir -p ~/.claude-code

# Create global Claude Code config
cat > ~/.config/claude-code/config.toml << 'EOF'
[permissions]
# Global permission settings
auto_approve = true
skip_confirmation = true
skip_file_confirmations = true
skip_command_confirmations = true
skip_fetch_confirmations = true

[allowed_paths]
# Directories with full access
paths = [
  "/Users/abhishek/Desktop",
  "/Users/abhishek/Downloads",
  "/Users/abhishek/DevKinsta",
  "/Users/abhishek/Work"
]

[mcp]
# Global MCP settings
auto_start = true
enabled = true

[commands]
# Commands that don't need confirmation
auto_approved = [
  "git", "npm", "node", "yarn", "pnpm",
  "ls", "cat", "grep", "find", "pwd",
  "echo", "mkdir", "cp", "mv", "touch",
  "chmod", "jest", "pytest", "prettier", "eslint"
]

[fetch]
# Auto-approve fetch for documentation sites
auto_approve_domains = [
  "docs.anthropic.com",
  "github.com",
  "stackoverflow.com",
  "developer.mozilla.org",
  "nodejs.org",
  "npmjs.com"
]
EOF

# Create user-level MCP config for Claude Code
cat > ~/.claude-code/mcp-config.json << 'EOF'
{
  "servers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/abhishek/Desktop",
        "/Users/abhishek/Downloads", 
        "/Users/abhishek/DevKinsta",
        "/Users/abhishek/Work"
      ]
    },
    "smart-operations": {
      "command": "node",
      "args": ["/Users/abhishek/Work/claude-automation/mcp-smart-ops.js"]
    },
    "github": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
EOF

# Install MCP servers globally
echo "📦 Installing MCP servers..."
npm install -g @modelcontextprotocol/server-filesystem @modelcontextprotocol/server-github

# Create Claude Code preferences file
cat > ~/.claude-code/preferences.json << 'EOF'
{
  "permissions": {
    "file_operations": {
      "require_confirmation": false,
      "allowed_operations": ["read", "write", "create", "delete", "rename"],
      "backup_on_delete": true
    },
    "command_execution": {
      "require_confirmation": false,
      "allowed_commands": ["*"]
    },
    "network_requests": {
      "require_confirmation": false,
      "allowed_domains": ["*"]
    }
  },
  "mcp": {
    "auto_connect": true,
    "servers": ["filesystem", "smart-operations", "github"]
  },
  "workspace": {
    "auto_approve_in_allowed_paths": true,
    "allowed_paths": [
      "/Users/abhishek/Desktop",
      "/Users/abhishek/Downloads",
      "/Users/abhishek/DevKinsta",
      "/Users/abhishek/Work"
    ]
  }
}
EOF

# Try to add MCP servers using Claude Code CLI
echo "🔗 Configuring MCP servers in Claude Code..."

# Create a setup script for Claude Code
cat > ~/.claude-code/setup-mcp.sh << 'EOF'
#!/bin/bash
# Run this in Claude Code to set up MCP servers

claude mcp add filesystem stdio npx -y @modelcontextprotocol/server-filesystem /Users/abhishek/Work /Users/abhishek/Desktop /Users/abhishek/Downloads /Users/abhishek/DevKinsta

claude mcp add smart-operations stdio node /Users/abhishek/Work/claude-automation/mcp-smart-ops.js

claude mcp add github stdio npx -y @modelcontextprotocol/server-github
EOF

chmod +x ~/.claude-code/setup-mcp.sh

echo "✅ Configuration files created!"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Restart Claude Code"
echo ""
echo "2. Run these commands in Claude Code:"
echo "   claude mcp add filesystem stdio npx -y @modelcontextprotocol/server-filesystem /Users/abhishek/Work"
echo "   claude mcp list"
echo ""
echo "3. If MCP servers still don't show, run:"
echo "   ~/.claude-code/setup-mcp.sh"
echo ""
echo "4. The .mcp.json file in your project should now work"
echo ""
echo "🎯 To stop permission prompts, Claude Code should now:"
echo "   - Auto-approve file operations in allowed directories"
echo "   - Skip confirmation for whitelisted commands"
echo "   - Auto-approve fetch requests"
