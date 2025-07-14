# Claude Docker Automation System

A comprehensive Docker-based solution for running Claude Code autonomously without permission prompts, inspired by the best practices from the community.

## 🎯 Features

- **Complete Isolation**: Claude runs safely in Docker containers
- **No Permission Prompts**: Uses `--dangerously-skip-permissions` safely
- **Autonomous Sessions**: 4-8+ hour uninterrupted coding sessions
- **Git Integration**: Automatic branch creation and commit management
- **Web Interface**: Monitor sessions through browser
- **Multi-Project**: Run multiple Claude instances simultaneously
- **Credential Management**: Secure credential forwarding

## 🚀 Quick Start

### 1. Setup

```bash
cd /Users/abhishek/Work/claude-docker-automation
chmod +x claude-docker.sh

# Build the Docker image (first time only)
./claude-docker.sh build
```

### 2. Start Your First Session

```bash
# Start in current directory
./claude-docker.sh start

# Start in specific project
./claude-docker.sh start /path/to/your/project

# 8-hour session with custom task file
./claude-docker.sh start /path/to/project tasks.md 8
```

### 3. Monitor and Manage

```bash
# List active sessions
./claude-docker.sh list

# Attach to running session
./claude-docker.sh attach

# Start web interface
./claude-docker.sh web

# Stop all sessions
./claude-docker.sh stop
```

## 📋 How It Works

1. **Docker Container**: Isolated environment with Claude Code pre-installed
2. **Task File**: Claude reads `CLAUDE_TASKS.md` for work instructions
   - Primary location: `/workspace/automation/claude-docker-automation/CLAUDE_TASKS.md`
   - Fallback location: `project-path/CLAUDE_TASKS.md`
3. **Autonomous Execution**: Claude works with full permissions inside container
4. **Progress Tracking**: Creates `PROGRESS.md`, `SUMMARY.md`, and `ISSUES.md`
5. **Git Management**: Automatic branch creation and commit handling

## 🛡️ Safety Features

### Container Isolation
- Complete separation from host system
- Network access controlled
- File system access limited to mounted directories
- No access to host credentials or sensitive data

### Git Safety
- Always creates new branches (never commits to main)
- Clear commit messages with session tracking
- Optional automatic push and PR creation
- Preserves git history and attribution

### Credential Security
- Read-only mounting of credential files
- Environment variable based API key management
- No permanent storage of secrets in container
- Optional credential forwarding

## 💾 Conversation Backup & Crash Protection

### Real-Time Backup System
- **Automatic conversation backup** every 30 seconds while working
- **Mac crash protection** - conversations saved even if system freezes
- **Multiple backup locations** - Regular + Real-time + Emergency recovery
- **Works from any directory** - `/Work/`, `/bank-nifty/`, any project location

### Quick Backup Commands
```bash
# Start real-time protection (30s intervals)
./claude-backup-alias.sh periodic start

# Manual backup current conversation
./claude-backup-alias.sh realtime

# Check protection status
./claude-backup-alias.sh periodic status

# Find your conversations
./claude-backup-alias.sh find "dashboard"
./claude-backup-alias.sh find "icici"
```

### After Mac Crash Recovery
```bash
# 1. Restart Mac, start Docker Desktop
# 2. Run automatic recovery
./crash-recovery-guide.sh recover

# 3. Find and restore your work
./claude-backup-alias.sh list
./claude-backup-alias.sh restore <session-id>
```

### Backup Locations
- **Real-time**: `~/.claude-docker-conversations/realtime/` (updated every 30s)
- **Regular**: `~/.claude-docker-conversations/conversations/` (full backups)
- **Emergency**: Desktop exports available via `./crash-recovery-guide.sh export`

## 📁 Project Structure

After running a session, your project will have:

```
your-project/
├── CLAUDE_TASKS.md      # Task instructions for Claude
├── PROGRESS.md          # Real-time progress updates
├── SUMMARY.md           # Final session summary
├── ISSUES.md            # Any problems encountered
├── .git/
│   └── refs/heads/
│       └── claude/session-20250106-143022  # Auto-created branch
└── your code files...
```

## ⚙️ Configuration

### Environment Variables

```bash
# Required for GitHub integration
export GITHUB_TOKEN="your_github_token"

# Required for Claude API access
export ANTHROPIC_API_KEY="your_api_key"

# Optional: Git identity
export GIT_USER_NAME="Your Name"
export GIT_USER_EMAIL="your@email.com"
```

### Task File Format

Create a `CLAUDE_TASKS.md` file in `/workspace/automation/claude-docker-automation/` with your instructions:

```markdown
# Claude Autonomous Work Session

## Project Overview
- **Goal**: Implement user authentication system
- **Scope**: Backend API with JWT tokens
- **Time Estimate**: 4 hours

## Tasks

### 1. Setup Authentication Module
- **Description**: Create auth folder structure
- **Requirements**: JWT, bcrypt, input validation
- **Acceptance Criteria**: Working login/register endpoints

### 2. Write Tests
- **Description**: Comprehensive test suite
- **Requirements**: Unit and integration tests
- **Acceptance Criteria**: >80% coverage

## Technical Requirements
- [ ] Follow existing code patterns
- [ ] Update documentation
- [ ] Create meaningful commits
- [ ] Handle error cases

## Deliverables
- [ ] Working authentication system
- [ ] Test coverage report
- [ ] Updated API documentation
- [ ] SUMMARY.md with results
```

## 🎮 Advanced Usage

### Multiple Sessions

```bash
# Terminal 1: Main development
./claude-docker.sh start main-app tasks-main.md 6

# Terminal 2: Testing & Documentation
./claude-docker.sh start test-suite tasks-test.md 4

# Terminal 3: Bug fixes
./claude-docker.sh start bug-fixes tasks-bugs.md 2
```

### Docker Compose

For more complex setups:

```bash
# Set your project path
export PROJECT_PATH=/path/to/your/project

# Start with compose
docker-compose up -d claude-automation

# With web interface
docker-compose --profile web up -d
```

### Custom Docker Image

Extend the base image for your needs:

```dockerfile
FROM claude-automation:latest

# Add your tools
RUN apt-get update && apt-get install -y \
    postgresql-client \
    redis-tools \
    python3-pip

# Install Python packages
RUN pip3 install pytest black flake8

# Add custom configuration
COPY custom-config.json /home/claude/.claude/
```

## 🔧 Customization

### Modify Default Behavior

Edit `~/.claude-docker/config.json`:

```json
{
  "defaultWorkspace": "/Users/abhishek/Work",
  "autoCommit": true,
  "autoPush": false,
  "branchPrefix": "claude/",
  "sessionTimeout": 14400,
  "maxTokens": 100000
}
```

### Custom Task Templates

Create reusable templates:

```bash
# API development template
cp templates/api-development.md CLAUDE_TASKS.md

# Bug fixing template  
cp templates/bug-fixes.md CLAUDE_TASKS.md

# Documentation template
cp templates/documentation.md CLAUDE_TASKS.md
```

## 📊 Monitoring

### Web Interface

Access the web UI at `http://localhost:3456`:

- Real-time session status
- Progress tracking
- Command shortcuts
- System health monitoring

### Command Line

```bash
# View logs
docker logs claude-session-myproject-20250106

# Follow session progress
tail -f /path/to/project/PROGRESS.md

# Check git activity
cd /path/to/project && git log --oneline claude/session-*
```

## 🚨 Troubleshooting

### Common Issues

1. **Docker Image Not Found**
   ```bash
   ./claude-docker.sh build
   ```

2. **Permission Denied**
   ```bash
   chmod +x claude-docker.sh
   chmod +x docker-entrypoint.sh
   ```

3. **API Key Not Working**
   ```bash
   echo $ANTHROPIC_API_KEY  # Should not be empty
   ```

4. **Git Credentials Missing**
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your@email.com"
   ```

### Debug Mode

Run with verbose output:

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  claude-automation:latest \
  bash -c "set -x && claude --dangerously-skip-permissions --version"
```

## 🔐 Security Considerations

### What's Safe
- Container isolation limits blast radius
- No access to host file system beyond mounted directories
- Read-only credential mounting
- Automatic git branching prevents main branch corruption

### What to Watch
- Network access within container (can make external requests)
- Mounted directories have full read/write access
- Generated code should be reviewed before production use
- API keys are visible within container environment

### Best Practices
- Use dedicated API keys for automation
- Regular backups of important projects
- Review generated code before merging
- Monitor resource usage for long sessions
- Keep the Docker image updated

## 📚 Examples

### Example 1: Web API Development

```bash
# Create task file
cat > CLAUDE_TASKS.md << 'EOF'
# Build REST API for Task Management

## Goal
Create a complete task management API with CRUD operations

## Tasks
1. Design database schema
2. Create Express.js server
3. Implement CRUD endpoints
4. Add input validation
5. Write comprehensive tests
6. Create API documentation

## Requirements
- Use TypeScript
- Follow REST conventions
- Include error handling
- 90%+ test coverage
EOF

# Start 6-hour session
./claude-docker.sh start . CLAUDE_TASKS.md 6
```

### Example 2: Code Refactoring

```bash
cat > CLAUDE_TASKS.md << 'EOF'
# Refactor Legacy Codebase

## Goal
Modernize and improve code quality

## Tasks
1. Analyze current code structure
2. Identify code smells and anti-patterns
3. Extract reusable components
4. Add TypeScript annotations
5. Improve error handling
6. Update documentation

## Requirements
- Maintain backward compatibility
- Add tests for refactored code
- Document breaking changes
- Create migration guide
EOF

./claude-docker.sh start legacy-project CLAUDE_TASKS.md 8
```

## 🤝 Contributing

Based on the excellent work from:
- [textcortex/claude-code-sandbox](https://github.com/textcortex/claude-code-sandbox)
- [brumar/jbsays](https://github.com/brumar/jbsays)
- [anthropics/claude-code](https://github.com/anthropics/claude-code)

## 📄 License

MIT License - Feel free to use and modify for your needs.

## 🆘 Support

1. Check the troubleshooting section above
2. Review Docker and Claude Code logs
3. Ensure all prerequisites are installed
4. Verify API keys and credentials are set correctly

---

**Happy Autonomous Coding!** 🚀

Let Claude handle the heavy lifting while you focus on the big picture.
