# Claude Docker Automation Analysis - Progress Report

## Project Analysis Complete ✅

### Understanding of claude-docker-automation Project

Based on the analysis of the codebase, here's how the Claude Docker automation system works:

#### 1. **Docker Container Structure**
- **Base Image**: `claude-automation:latest` built from Dockerfile
- **User**: `claude` (non-root user inside container)
- **Working Directory**: `/workspace` (where projects are mounted)
- **Claude Config**: `/home/claude/.claude` (persistent volume)

#### 2. **Key Volume Mounts** 
From `docker-compose.yml` and `claude-auto.sh`:
```yaml
volumes:
  - ${PROJECT_PATH:-.}:/workspace              # Project files
  - ${HOME}/.gitconfig:/home/claude/.gitconfig # Git config (read-only)
  - claude-code-config:/home/claude/.claude    # Persistent Claude config (VOLUME)
```

#### 3. **Claude Data Path Inside Containers**
- **Claude Configuration Directory**: `/home/claude/.claude`
- **Projects Data**: `/home/claude/.claude/projects/`
- **Usage History (JSONL files)**: `/home/claude/.claude/projects/**/*.jsonl`

#### 4. **Container Launch Methods**
The system provides multiple ways to launch Claude containers:
- `claude-auto.sh` - Fully automated sessions
- `claude-web-auto.sh` - Web interface automation
- `claude-direct-task.sh` - Direct task execution
- `docker-compose.yml` - Compose-based deployment

## ccusage Path Analysis ✅

### Key Finding: Claude Data Location

Inside the Docker containers, Claude Code stores its data in:
- **Main Config**: `/home/claude/.claude/`
- **Projects**: `/home/claude/.claude/projects/`
- **Usage Files**: `/home/claude/.claude/projects/**/*.jsonl`

### ccusage Commands for Docker Containers

Since the Claude data is stored inside Docker containers at `/home/claude/.claude`, you would need to:

1. **Run ccusage inside the container** (recommended):
```bash
# Access running container
docker exec -it claude-session-PROJECT-TIMESTAMP bash

# Then run ccusage inside container
npx ccusage@latest daily --path /home/claude/.claude
```

2. **Access via volume mounts** (if volume is accessible):
```bash
# First identify the volume
docker volume inspect claude-code-config

# Then run ccusage pointing to volume mount point
ccusage daily --path /var/lib/docker/volumes/claude-code-config/_data
```

### Next Steps
- Document the exact commands to use
- Test the ccusage integration
- Create usage examples