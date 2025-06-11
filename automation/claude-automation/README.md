# Claude Max Automation System 🚀

A comprehensive automation system that maximizes your Claude Max subscription by enabling autonomous coding sessions, multi-Claude collaboration, and minimal manual intervention.

## 🎯 Features

- **Autonomous Coding**: Launch Claude for 4-10 hour unattended coding sessions
- **Smart Backups**: Automatic versioned backups before any file modification
- **Breaking Change Detection**: Stops work if breaking changes are detected
- **Multi-Claude Collaboration**: Run multiple Claude instances working together WITHOUT expensive APIs
- **GitHub Integration**: Automatic branch creation, commits, and PR generation
- **Real-time Dashboard**: Monitor all activity through a beautiful web interface
- **MCP Server Integration**: Custom tools for safe file operations

## 🚀 Quick Start (5 Minutes)

```bash
# 1. Run the setup script
cd /Users/abhishek/Work/claude-automation
chmod +x quick-setup.sh
./quick-setup.sh

# 2. Add aliases to your shell
echo 'source /Users/abhishek/Work/claude-automation/setup-aliases.sh' >> ~/.zshrc
source ~/.zshrc

# 3. Create your first task
claude-task

# 4. Launch automation (4 hours)
claude-work 4

# 5. Open dashboard
claude-dash
```

## 📁 Directory Structure

```
claude-automation/
├── instructions/          # Task templates and daily instructions
├── backups/              # Automatic file backups
├── logs/                 # Session logs
├── reports/              # Post-session reports
├── collaboration/        # Multi-Claude collaboration system
├── dashboard/            # Web monitoring interface
├── templates/            # Reusable task templates
├── mcp-smart-ops.js      # Custom MCP server for smart operations
├── ultimate-launch.sh    # Main automation launcher
└── setup-collaboration.sh # Multi-Claude setup
```

## 🎮 Daily Workflow

### Morning (5 minutes)
1. Create today's task file:
   ```bash
   claude-task
   ```
2. Edit with your specific tasks
3. Launch automation:
   ```bash
   claude-work 4  # Run for 4 hours
   ```

### Evening (5 minutes)
1. Review the generated PR on GitHub
2. Check session report
3. Merge if everything looks good

## 🤖 Multi-Claude Collaboration (No APIs!)

Run multiple Claude instances that work together WITHOUT using expensive APIs:

```bash
# Set up collaboration system
./setup-collaboration.sh

# Launch orchestrator
/Users/abhishek/Work/claude-automation/collaboration/orchestrate.sh
```

This creates:
- **Developer Claude**: Writes code (Claude Code terminal)
- **Reviewer Claude**: Reviews code (Claude Desktop app)
- **Tester AI**: Generates tests (Google AI Studio - FREE)
- **Documenter**: Creates documentation

They communicate through shared files, not APIs!

## 🛡️ Safety Features

1. **Automatic Backups**: Every file is backed up before modification
2. **Breaking Change Detection**: Work stops if breaking changes detected
3. **Branch Protection**: Never commits directly to main
4. **Force Operations**: No permission prompts for whitelisted commands
5. **Project Snapshots**: Full project backup before each session

## 🔧 MCP Server Tools

The custom MCP server provides:
- `versioned_backup`: Git-like versioned backups
- `safe_delete`: Moves to trash instead of deleting
- `detect_api_changes`: Analyzes breaking changes
- `force_operation`: Runs commands without prompts
- `create_snapshot`: Full project snapshots

## 📊 Monitoring

Access the real-time dashboard:
```bash
claude-dash
# OR
open /Users/abhishek/Work/claude-automation/dashboard/index.html
```

Monitor:
- Active sessions
- Tasks completed
- Success rate
- Time saved
- Live activity feed
- Claude instance status

## 🎯 Task Templates

Pre-built templates for common tasks:
- `api-endpoint.md`: REST API implementation
- `bug-fix.md`: Bug fixing workflow
- `new-feature.md`: Feature development

Copy and customize:
```bash
cp templates/tasks/api-endpoint.md instructions/today.md
```

## ⚡ Aliases

After setup, use these shortcuts:

```bash
claude-work [hours]     # Launch automation
claude-dash            # Open dashboard
claude-logs            # View logs
claude-backup          # Check backups
claude-collab          # Start collaboration
claude-status          # Check running instances
claude-task            # Create new task
claude-session start   # Start session
claude-session stop    # Stop all sessions
```

## 🔐 Configuration

### MCP Servers
Configured in: `~/Library/Application Support/Claude/claude_desktop_config.json`

Includes:
- Filesystem access to your work directories
- Smart operations server
- GitHub integration
- AppleScript automation
- Browser control

### Environment Variables
Create `.env` from template:
```bash
cp .env.template .env
```

Add your tokens (optional for API-based features).

## 🚨 Troubleshooting

### Claude Code not found
```bash
npm install -g @anthropic-ai/claude-code
```

### MCP server not connecting
```bash
# Check logs
tail -f ~/Library/Logs/Claude/mcp-server-*.log

# Restart Claude Desktop
```

### Permission denied
```bash
chmod +x /Users/abhishek/Work/claude-automation/*.sh
```

## 💡 Pro Tips

1. **Start Small**: Begin with 2-4 hour sessions
2. **Clear Instructions**: Be specific in task descriptions
3. **Use Templates**: Build a library of task templates
4. **Monitor First Sessions**: Watch the first few runs closely
5. **Incremental Tasks**: Break large projects into smaller tasks

## 🎉 Benefits

- **95% Time Savings**: 5 minutes setup → 4-10 hours autonomous work
- **Consistent Quality**: Automated testing and code review
- **Zero Context Switching**: Claude handles the entire workflow
- **Cost Effective**: Multi-Claude collaboration without API costs
- **Full Control**: Everything runs locally with your oversight

## 📚 Advanced Usage

### Custom MCP Tools
Add new tools to `mcp-smart-ops.js`:

```javascript
{
  name: 'your_tool',
  description: 'What it does',
  inputSchema: { /* ... */ },
  handler: async (args) => { /* ... */ }
}
```

### Workflow Automation
Create complex workflows in task files:

```markdown
## Workflow: Full Feature Implementation
1. Create feature branch
2. Implement backend API
3. Add database migrations
4. Write comprehensive tests
5. Create frontend components
6. Update documentation
7. Create pull request
```

## 🤝 Support

- **Issues**: Create in your project's issue tracker
- **Logs**: Check `/Users/abhishek/Work/claude-automation/logs/`
- **Backups**: Available in `/Users/abhishek/Work/claude-automation/backups/`

---

Built with ❤️ to maximize your Claude Max subscription and minimize your effort!
