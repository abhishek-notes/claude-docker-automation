# Claude Collaboration System Guide

## Overview

The Claude Collaboration System (`claude-collab.sh`) enables two Claude Code instances to work together autonomously on complex tasks. It follows the same proven patterns as your existing `claude-auto.sh` system with persistent memory and session management.

## Quick Start

### 1. Start a Collaboration Session
```bash
./claude-collab.sh start /path/to/your/project "Analyze and improve the authentication system"
```

### 2. Monitor the Collaboration
```bash
./claude-collab.sh monitor /path/to/your/project
```

### 3. Send Messages to Instances
```bash
./claude-collab.sh message alice "Focus on backend security vulnerabilities"
./claude-collab.sh message bob "Create comprehensive test coverage"
```

### 4. Check Status
```bash
./claude-collab.sh status /path/to/your/project
```

## How It Works

### 🧠 **Persistent Memory**
- Uses Docker volumes for persistent storage across sessions
- Each instance maintains its own memory and work history
- Shared collaboration workspace persists between runs

### 👥 **Two Claude Instances**
- **Alice**: Primary Developer (Backend, Architecture)
- **Bob**: Secondary Developer (Frontend, Testing)
- Each has distinct roles and specialties

### 📁 **File Structure**
```
your-project/
└── collaboration/
    ├── messages/           # Communication
    │   ├── alice-inbox.md
    │   ├── alice-outbox.md  
    │   ├── bob-inbox.md
    │   └── bob-outbox.md
    ├── status/             # Real-time status
    │   ├── alice-status.json
    │   └── bob-status.json
    ├── outputs/            # Work logs
    │   ├── alice-work.md
    │   └── bob-work.md
    ├── shared/             # Shared files
    └── tasks/              # Task assignments
```

### 🔄 **Communication Protocol**
Claude instances communicate through structured markdown messages:

```markdown
## Message from alice - 2025-06-07T11:30:00Z
**Type**: update
**Priority**: medium
**Content**: Completed security audit of authentication module
**Files**: auth-audit-report.md
**RequiresResponse**: false
```

## Features

### ✅ **What's Included**
- **Persistent Memory**: Sessions survive container restarts
- **Real-time Monitoring**: tmux-based dashboard with 4 windows
- **Message System**: Structured communication between instances
- **Status Tracking**: JSON status files with progress updates
- **Work Logging**: Detailed logs of each instance's work
- **Shared Workspace**: Common area for file collaboration
- **Session Management**: Start, stop, monitor multiple sessions

### 🚀 **Advanced Usage**

#### Multiple Sessions
```bash
# Start multiple projects
./claude-collab.sh start /project1 "Improve performance"
./claude-collab.sh start /project2 "Add new features" 

# Monitor specific session
./claude-collab.sh monitor /project1 20250607-143021
```

#### Message Broadcasting
```bash
# Send to both instances
./claude-collab.sh message alice "New requirements added" /project1
./claude-collab.sh message bob "New requirements added" /project1
```

#### Session Management
```bash
# Stop specific session
./claude-collab.sh stop 20250607-143021

# Stop all sessions
./claude-collab.sh stop
```

## Monitoring Dashboard

The `monitor` command opens a tmux session with 4 windows:

1. **Alice**: Direct terminal access to Alice instance
2. **Bob**: Direct terminal access to Bob instance  
3. **Messages**: Live view of message exchanges
4. **Status**: Real-time status and work log monitoring

### tmux Navigation
- `Ctrl+b, n`: Next window
- `Ctrl+b, p`: Previous window
- `Ctrl+b, 0-3`: Go to specific window
- `Ctrl+b, d`: Detach (keeps running)

## Integration with Existing System

### Uses Same Infrastructure
- **Docker Image**: `claude-automation:latest`
- **Config Volume**: `claude-code-config` 
- **Security Model**: Same container isolation
- **Permissions**: `--dangerously-skip-permissions`

### Compatible Commands
```bash
# Works alongside existing scripts
./claude-auto.sh        # Single instance automation
./claude-collab.sh      # Dual instance collaboration
./claude-direct-task.sh # Direct task injection
```

## Example Workflows

### 1. Code Review & Enhancement
```bash
./claude-collab.sh start ~/my-app "Review and enhance the user authentication system"

# Alice focuses on backend security
./claude-collab.sh message alice "Analyze backend auth vulnerabilities and security patterns"

# Bob handles testing and frontend
./claude-collab.sh message bob "Create comprehensive tests and improve login UX"
```

### 2. Bug Investigation
```bash
./claude-collab.sh start ~/buggy-app "Investigate and fix the payment processing bug"

# Let them coordinate automatically
./claude-collab.sh monitor ~/buggy-app
```

### 3. Feature Development
```bash
./claude-collab.sh start ~/feature-branch "Implement real-time chat feature"

# Provide additional context
./claude-collab.sh message alice "Focus on WebSocket backend and data architecture" 
./claude-collab.sh message bob "Build responsive chat UI with typing indicators"
```

## Troubleshooting

### Common Issues

#### Docker Permissions
```bash
# If containers fail to start
docker volume ls | grep claude
docker volume rm claude-code-config  # Reset if needed
./claude-collab.sh start ...
```

#### Message Delivery
```bash
# Check message files directly
cat ~/project/collaboration/messages/alice-inbox.md
cat ~/project/collaboration/status/alice-status.json
```

#### Session Cleanup
```bash
# Clean up stuck containers
docker ps -q --filter "name=claude-collab-" | xargs docker stop
docker ps -aq --filter "name=claude-collab-" | xargs docker rm
```

### Performance Tips

1. **Use specific task descriptions** for better coordination
2. **Monitor regularly** to catch issues early  
3. **Send clarifying messages** when needed
4. **Check status files** for progress updates

## Security

### Container Isolation
- Same security model as existing system
- No host system access
- Container-only file operations
- Network isolation maintained

### Data Persistence
- Collaboration data stored in project directory
- Persistent volumes for session memory
- No sensitive data exposure

This system provides powerful collaboration capabilities while maintaining the security and reliability of your existing Claude automation infrastructure.