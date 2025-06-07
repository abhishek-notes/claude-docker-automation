# Claude Collaboration Guide

## The Problem
Claude Code requires manual input at startup - it doesn't automatically read task files. This is why previous automated approaches failed.

## The Solution
We've created two approaches that handle this requirement:

### 1. Manual Collaboration System (`claude-manual-collab.sh`)
Best for: Quick setup, full control, tmux users

**Features:**
- Uses tmux to manage multiple Claude instances
- Shared collaboration directory
- Clear prompts to copy/paste
- Real-time monitoring

**Quick Start:**
```bash
# Start with tmux (recommended)
./claude-manual-collab.sh tmux

# Or use separate terminals
./claude-manual-collab.sh terminals

# Get prompts to copy/paste
./claude-manual-collab.sh prompts
```

### 2. Docker Compose System (`claude-compose-collab.sh`)
Best for: Production use, easier management, persistent setup

**Features:**
- Docker Compose orchestration
- Named volumes for persistence
- Easy start/stop/attach commands
- Built-in monitoring

**Quick Start:**
```bash
# Start collaboration
./claude-compose-collab.sh start /path/to/project

# Attach to instances (in separate terminals)
./claude-compose-collab.sh attach alice
./claude-compose-collab.sh attach bob

# Monitor collaboration
./claude-compose-collab.sh monitor
```

## How It Works

1. **Start Containers**: Each Claude instance runs in its own Docker container
2. **Manual Initialization**: You manually start Claude with `claude --dangerously-skip-permissions`
3. **Paste Prompts**: Copy/paste the role-specific prompts that define each Claude's identity and tasks
4. **Collaboration**: Claude instances communicate through shared directories

## Collaboration Structure

```
/collab/
├── alice/              # Alice's workspace
│   ├── findings.md     # Alice's analysis
│   ├── questions-for-bob.md
│   └── answers-for-bob.md
├── bob/                # Bob's workspace
│   ├── findings.md     # Bob's analysis
│   ├── questions-for-alice.md
│   └── answers-for-alice.md
└── shared/             # Shared files
    ├── collaboration-protocol.md
    └── [shared code files]
```

## Example Prompts

### For Alice (Backend Analyst):
```
You are Alice, a backend analyst working collaboratively with Bob (frontend specialist). 

Your collaboration directory is /collab with this structure:
- /collab/alice/ - Your workspace
- /collab/bob/ - Bob's workspace  
- /collab/shared/ - Shared files

Tasks:
1. Analyze the backend code in /workspace
2. Document findings in /collab/alice/findings.md
3. Check /collab/bob/questions-for-alice.md periodically
4. Answer Bob's questions in /collab/alice/answers-for-bob.md
5. Ask Bob questions in /collab/alice/questions-for-bob.md

Start by reading /collab/shared/collaboration-protocol.md then analyzing the backend.
```

### For Bob (Frontend Specialist):
```
You are Bob, a frontend specialist working collaboratively with Alice (backend analyst).

Your collaboration directory is /collab with this structure:
- /collab/bob/ - Your workspace
- /collab/alice/ - Alice's workspace
- /collab/shared/ - Shared files

Tasks:
1. Analyze the frontend code in /workspace
2. Document findings in /collab/bob/findings.md
3. Check /collab/alice/questions-for-bob.md periodically
4. Answer Alice's questions in /collab/bob/answers-for-alice.md
5. Ask Alice questions in /collab/bob/questions-for-alice.md

Start by reading /collab/shared/collaboration-protocol.md then analyzing the frontend.
```

## Tips for Effective Collaboration

1. **Regular Check-ins**: Have Claude instances check for questions every 10-15 minutes
2. **Clear Communication**: Encourage Claude to write clear, specific questions
3. **Code Sharing**: Use `/collab/shared/` for code snippets and examples
4. **Progress Updates**: Have Claude update findings.md regularly
5. **Task Coordination**: You can update their tasks by sending new messages

## Troubleshooting

**Claude not starting?**
- Make sure Docker image is built: `./claude-docker.sh build`
- Check Docker is running: `docker ps`

**Can't see collaboration files?**
- Check volume is created: `docker volume ls | grep collaboration`
- Verify mount paths in containers

**Claude not responding to prompts?**
- Ensure you're using `--dangerously-skip-permissions`
- Try simpler initial prompts first
- Check for API key issues

## Advanced Usage

### Custom Roles
Create specialized Claude instances:
- Security Analyst
- Performance Optimizer  
- Test Engineer
- Documentation Writer

### Multiple Projects
Run separate collaboration sessions for different projects using different Docker Compose project names.

### Persistent Collaboration
Use named volumes to maintain collaboration state across sessions.