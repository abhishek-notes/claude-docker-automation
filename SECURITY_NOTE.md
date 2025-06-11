# 🔒 SECURITY CONFIGURATION

## Container Isolation Enforced

This setup ensures Claude operates **ONLY within Docker containers** with no host system access.

### ✅ What's Protected:
- **Host filesystem**: Claude cannot access `/Users/`, `/home/`, `/etc/`, etc.
- **System commands**: No `sudo`, `systemctl`, `mount`, etc.
- **Network access**: No external web requests from container
- **Host processes**: Cannot interact with host system processes

### ✅ What's Allowed (Container Only):
- File operations within `/app/`, `/workspace/`, `/tmp/`
- Development commands: `git`, `npm`, `node`, `python`, etc.
- Basic shell commands: `ls`, `cat`, `grep`, `mkdir`, etc.

### 🔧 Configuration Files:
- `.clauderc` - Tool permissions (container-restricted)
- `.claude-code.toml` - Workspace permissions (container-only paths)
- `install-mcp.sh` - MCP server for Claude Desktop (host-side safety)

### ⚠️ Important Notes:
1. **MCP Server runs on HOST** - provides safety features for Claude Desktop
2. **Docker Claude is ISOLATED** - cannot access host or network
3. **GitHub token in .env** - only used by host scripts, not container Claude
4. **Web interface runs on HOST** - manages container launching only

### 🛡️ Security Layers:
1. **Docker containerization** - Physical isolation
2. **Permission configs** - Tool and path restrictions  
3. **Command whitelisting** - Only approved commands
4. **Path restrictions** - Container filesystem only
5. **Network isolation** - No external access

## GitHub Token Status: ✅ FOUND AND CONFIGURED
- Token: `[REDACTED FOR SECURITY]`
- Source: `/Users/abhishek/Work/coin-flip-app/.env`
- Username: `abhishek-notes`
- Email: `abhisheksoni1551@gmail.com`

This token is used **only by host automation scripts**, never exposed to container Claude.