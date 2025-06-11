# Claude Code MCP Setup Guide 🔧

## The Problem
Claude Code uses a different MCP configuration system than Claude Desktop. You need to configure it properly to:
1. Enable MCP servers
2. Stop permission prompts
3. Have full access in allowed directories

## Quick Fix

Run this script:
```bash
/Users/abhishek/Work/claude-automation/fix-claude-code-permissions.sh
```

## Manual Setup Steps

### 1. Add MCP Servers in Claude Code

Open Claude Code and run these commands one by one:

```bash
# Add filesystem server
claude mcp add filesystem stdio npx -y @modelcontextprotocol/server-filesystem /Users/abhishek/Work /Users/abhishek/Desktop /Users/abhishek/Downloads /Users/abhishek/DevKinsta

# Add smart operations server
claude mcp add smart-operations stdio node /Users/abhishek/Work/claude-automation/mcp-smart-ops.js

# Add GitHub server
claude mcp add github stdio npx -y @modelcontextprotocol/server-github

# List configured servers
claude mcp list
```

### 2. Project-Level Configuration

I've already created these files in your project:

#### `.mcp.json` (for MCP servers)
```json
{
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
  }
}
```

#### `.claude-code.toml` (for permissions)
```toml
[permissions]
allow = ["read", "write", "rename", "execute", "create", "delete"]
auto_approve = true
skip_confirmation = true

[automation]
skip_file_confirmations = true
skip_command_confirmations = true
skip_fetch_confirmations = true
```

### 3. Global Configuration Files Created

The script creates these global configs:

1. `~/.config/claude-code/config.toml` - Global permissions
2. `~/.claude-code/mcp-config.json` - MCP server definitions
3. `~/.claude-code/preferences.json` - Claude Code preferences

### 4. Environment Variables

Add to your `~/.zshrc`:

```bash
# Claude Code permissions
export CLAUDE_CODE_AUTO_APPROVE=true
export CLAUDE_CODE_SKIP_CONFIRMATIONS=true
```

## Verification

After setup, test in Claude Code:

```bash
# Check MCP servers
/mcp

# Should show:
# - filesystem
# - smart-operations  
# - github

# Test file operations (should not ask permission)
cat README.md
ls -la
```

## Troubleshooting

### MCP servers not showing?

1. **Check if servers are added:**
   ```bash
   claude mcp list
   ```

2. **Re-add servers:**
   ```bash
   claude mcp remove filesystem
   claude mcp add filesystem stdio npx -y @modelcontextprotocol/server-filesystem /Users/abhishek/Work
   ```

3. **Check MCP config location:**
   ```bash
   # Claude Code might store configs in:
   ls ~/.claude-code/
   ls ~/.config/claude-code/
   ls ~/Library/Application\ Support/claude-code/
   ```

### Still getting permission prompts?

1. **Ensure `.claude-code.toml` exists in your project**
2. **Check if environment variables are set:**
   ```bash
   echo $CLAUDE_CODE_AUTO_APPROVE
   ```
3. **Try adding to project root:**
   ```bash
   echo "auto_approve = true" > .clauderc
   ```

### Alternative: Use Command Flags

When running Claude Code:
```bash
# Start with auto-approve
claude --auto-approve

# Or set alias
alias claude='claude --auto-approve --skip-confirmations'
```

## Expected Behavior After Setup

✅ No permission prompts for:
- File read/write in allowed directories
- Running whitelisted commands
- Fetching from documentation sites

✅ MCP servers available:
- `filesystem` - Full file access
- `smart-operations` - Backup and safety tools
- `github` - GitHub integration

✅ Automatic operations:
- File backups before modifications
- Branch creation
- Commit operations

## Note on Claude Code vs Claude Desktop

- **Claude Desktop**: Uses `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Claude Code**: Uses project `.mcp.json` and user configs in `~/.claude-code/`

They share the same MCP servers but have different configuration locations!
