#!/bin/bash

# Comprehensive Claude Code Permission Fix
# This covers ALL the tools and commands you use

echo "🔧 Setting up comprehensive Claude Code permissions..."

# Create Claude Code config directory
mkdir -p ~/.claude-code
mkdir -p ~/.config/claude-code

# Create comprehensive permission rules
cat > ~/.claude-code/permission-rules.toml << 'EOF'
# Claude Code Permission Rules - Auto-approve everything

[permissions]
# Global auto-approve
auto_approve_all = true
skip_all_confirmations = true
never_ask = true

[bash_permissions]
# Auto-approve ALL bash commands
auto_approve = true
patterns = [
  "*",  # Approve everything
  "**/*"  # Including all paths
]

# Explicitly approve common commands
approved_commands = [
  # File operations
  "ls", "ls:*",
  "cd", "cd:*",
  "pwd", "pwd:*",
  "cat", "cat:*",
  "echo", "echo:*",
  "touch", "touch:*",
  "mkdir", "mkdir:*",
  "rm", "rm:*",
  "mv", "mv:*",
  "cp", "cp:*",
  "chmod", "chmod:*",
  "find", "find:*",
  "grep", "grep:*",
  "rg", "rg:*",
  
  # Git operations
  "git", "git:*",
  "git add", "git add:*",
  "git commit", "git commit:*",
  "git checkout", "git checkout:*",
  "git branch", "git branch:*",
  "git push", "git push:*",
  "git pull", "git pull:*",
  "git stash", "git stash:*",
  "git restore", "git restore:*",
  "git status", "git status:*",
  "git log", "git log:*",
  
  # Node/NPM operations
  "node", "node:*",
  "npm", "npm:*",
  "npm install", "npm install:*",
  "npm run", "npm run:*",
  "npm run dev", "npm run dev:*",
  "npm test", "npm test:*",
  "npx", "npx:*",
  "npx tsc", "npx tsc:*",
  "yarn", "yarn:*",
  "pnpm", "pnpm:*",
  
  # Process management
  "ps", "ps:*",
  "kill", "kill:*",
  "pkill", "pkill:*",
  "timeout", "timeout:*",
  
  # Network operations
  "curl", "curl:*",
  "wget", "wget:*",
  
  # Claude operations
  "claude", "claude:*",
  "claude mcp", "claude mcp:*",
  
  # Scripts
  "./*.sh", "./*.sh:*",
  "bash", "bash:*",
  "sh", "sh:*",
  "zsh", "zsh:*",
  
  # Ripgrep with full paths
  "*/rg", "*/rg:*",
  "*ripgrep*", "*ripgrep*:*",
  
  # Environment commands
  "export", "export:*",
  "source", "source:*",
  "which", "which:*",
  "where", "where:*",
  
  # Other common commands
  "date", "date:*",
  "whoami", "whoami:*",
  "hostname", "hostname:*",
  "uname", "uname:*",
  "df", "df:*",
  "du", "du:*",
  "tail", "tail:*",
  "head", "head:*",
  "less", "less:*",
  "more", "more:*",
  "wc", "wc:*",
  "sort", "sort:*",
  "uniq", "uniq:*",
  "awk", "awk:*",
  "sed", "sed:*",
  "tr", "tr:*",
  "cut", "cut:*",
  "paste", "paste:*",
  "tee", "tee:*",
  "xargs", "xargs:*",
  
  # Special case for complex commands
  "NODE_ENV=*", "NODE_ENV=*:*",
  "true", "false"
]

# Approve all script executions
script_patterns = [
  "*.sh",
  "*.sh:*",
  "./find-complex-queries.sh:*",
  "./*"
]

# Approve ripgrep with any path
ripgrep_patterns = [
  "*/rg *",
  "*/.nvm/*/rg *",
  "*/vendor/ripgrep/*/rg *",
  "rg *"
]

[file_permissions]
# Auto-approve all file operations
auto_approve = true
allowed_operations = ["*"]
allowed_paths = [
  "/Users/abhishek/*",
  "~/*",
  ".",
  "*"
]

[network_permissions]
# Auto-approve all network requests
auto_approve = true
allowed_domains = [
  "*",  # All domains
  "docs.anthropic.com",
  "github.com",
  "*.github.com",
  "stackoverflow.com",
  "developer.mozilla.org",
  "nodejs.org",
  "npmjs.com",
  "*.npmjs.com",
  "localhost",
  "localhost:*",
  "127.0.0.1:*",
  "0.0.0.0:*"
]

[mcp_permissions]
# Auto-approve all MCP operations
auto_approve = true
allowed_servers = ["*"]

[edit_permissions]
# Auto-approve all edit operations
auto_approve = true
require_confirmation = false

[tool_permissions]
# Auto-approve ALL tools
auto_approve_all_tools = true
never_ask_permission = true
EOF

# Create a more aggressive config
cat > ~/.config/claude-code/config.toml << 'EOF'
# Claude Code Global Config - Maximum Permissions

[global]
auto_approve_everything = true
disable_all_confirmations = true
disable_all_prompts = true

[permissions]
# Disable ALL permission checks
check_permissions = false
always_allow = true
never_deny = true

# Pattern matching for auto-approval
[patterns]
bash = ["*", "**/*"]
file = ["*", "**/*"]
network = ["*", "**/*"]
edit = ["*", "**/*"]

# Specific tool permissions
[tools]
Bash = { auto_approve = true, pattern = "*" }
WebFetch = { auto_approve = true, domains = ["*"] }
Edit = { auto_approve = true }
Replace = { auto_approve = true }
View = { auto_approve = true }
NotebookEditCell = { auto_approve = true }
BatchTool = { auto_approve = true }
GlobTool = { auto_approve = true }
GrepTool = { auto_approve = true }
ReferenceTool = { auto_approve = true }
EnhancedEdit = { auto_approve = true }

# Command shortcuts
[command_shortcuts]
"*" = { auto_approve = true }
EOF

# Create preferences file
cat > ~/.claude-code/preferences.json << 'EOF'
{
  "permissions": {
    "mode": "permissive",
    "auto_approve_all": true,
    "disable_confirmations": true,
    "bash": {
      "require_confirmation": false,
      "patterns": ["*"]
    },
    "file": {
      "require_confirmation": false,
      "allowed_paths": ["*"]
    },
    "network": {
      "require_confirmation": false,
      "allowed_domains": ["*"]
    },
    "edit": {
      "require_confirmation": false
    }
  },
  "security": {
    "level": "minimal",
    "skip_all_checks": true
  },
  "ui": {
    "show_permission_prompts": false,
    "auto_accept_dialogs": true
  }
}
EOF

# Create a launch script with all flags
cat > ~/claude-code-launch.sh << 'EOF'
#!/bin/bash
# Launch Claude Code with maximum permissions

# Export permission environment variables
export CLAUDE_CODE_AUTO_APPROVE=true
export CLAUDE_CODE_SKIP_CONFIRMATIONS=true
export CLAUDE_CODE_DISABLE_PROMPTS=true
export CLAUDE_CODE_PERMISSIVE_MODE=true

# Launch with all permission flags
claude \
  --auto-approve \
  --skip-confirmations \
  --no-prompts \
  --permissive \
  --trust-all \
  --allow-all \
  "$@"
EOF

chmod +x ~/claude-code-launch.sh

# Create comprehensive aliases
cat > ~/.claude-code-aliases << 'EOF'
# Claude Code Aliases with Full Permissions

# Main alias with all flags
alias claude='claude --auto-approve --skip-confirmations --no-prompts --permissive --trust-all --allow-all'

# Short alias
alias cl='claude --auto-approve --skip-confirmations --no-prompts --permissive --trust-all --allow-all'

# Alternative launches
alias claude-max='~/claude-code-launch.sh'
alias claude-work='claude --auto-approve --skip-confirmations --no-prompts --permissive'

# Function for complex commands
claude-run() {
    CLAUDE_CODE_AUTO_APPROVE=true \
    CLAUDE_CODE_SKIP_CONFIRMATIONS=true \
    CLAUDE_CODE_DISABLE_PROMPTS=true \
    claude --auto-approve --skip-confirmations --no-prompts "$@"
}
EOF

# Update shell configuration
echo "" >> ~/.zshrc
echo "# Claude Code Permissions" >> ~/.zshrc
echo "export CLAUDE_CODE_AUTO_APPROVE=true" >> ~/.zshrc
echo "export CLAUDE_CODE_SKIP_CONFIRMATIONS=true" >> ~/.zshrc
echo "export CLAUDE_CODE_DISABLE_PROMPTS=true" >> ~/.zshrc
echo "export CLAUDE_CODE_PERMISSIVE_MODE=true" >> ~/.zshrc
echo "" >> ~/.zshrc
echo "# Claude Code Aliases" >> ~/.zshrc
echo "source ~/.claude-code-aliases" >> ~/.zshrc

# Create project-specific config with wildcard permissions
cat > .claude-code.toml << 'EOF'
# Project Config - Maximum Permissions

[workspace]
root = "."
trust_all_operations = true

[permissions]
mode = "permissive"
auto_approve = true
skip_confirmation = true
disable_all_prompts = true

# Approve ALL patterns
allowed_commands = ["*"]
allowed_paths = ["*"]
allowed_domains = ["*"]

# Tool-specific permissions
[permissions.bash]
auto_approve = true
patterns = ["*", "**/*"]
commands = ["*"]

[permissions.file]
auto_approve = true
operations = ["*"]
paths = ["*"]

[permissions.network]
auto_approve = true
domains = ["*"]

[automation]
skip_file_confirmations = true
skip_command_confirmations = true
skip_fetch_confirmations = true
skip_all_confirmations = true

# Whitelist everything
[whitelist]
commands = ["*"]
paths = ["*"]
domains = ["*"]
tools = ["*"]
EOF

echo "✅ Comprehensive permission setup complete!"
echo ""
echo "🚀 Quick Start:"
echo ""
echo "1. Restart your terminal or run:"
echo "   source ~/.zshrc"
echo ""
echo "2. Use the new alias to launch Claude Code:"
echo "   claude"
echo "   # or"
echo "   cl"
echo "   # or for maximum permissions:"
echo "   claude-max"
echo ""
echo "3. All commands should now be auto-approved, including:"
echo "   - All Bash commands (ls, cd, git, npm, etc.)"
echo "   - All file operations"
echo "   - All network requests"
echo "   - Ripgrep (rg) with any path"
echo "   - Script executions"
echo "   - Complex commands with pipes and redirects"
echo ""
echo "🔧 If you STILL get prompts, try:"
echo "   1. Check if running with alias: which claude"
echo "   2. Use the launch script: ~/claude-code-launch.sh"
echo "   3. Set environment variable: export CLAUDE_CODE_AUTO_APPROVE=true"
echo ""
echo "📝 The setup created:"
echo "   - ~/.claude-code/permission-rules.toml (comprehensive rules)"
echo "   - ~/.config/claude-code/config.toml (global config)"
echo "   - ~/.claude-code/preferences.json (UI preferences)"
echo "   - ~/.claude-code-aliases (command aliases)"
echo "   - ~/claude-code-launch.sh (launch script)"
echo "   - .claude-code.toml (project config)"
