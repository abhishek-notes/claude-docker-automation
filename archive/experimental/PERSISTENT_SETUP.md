# Claude Docker with Persistent Configuration

This solution fixes the issue of Claude Code asking for setup (theme, login) every time by using Docker volumes to persist configuration between runs.

## The Problem
- Claude Code stores its configuration in `~/.claude/` directory
- Without persistence, each container starts fresh
- Results in theme selection and login prompts every time

## The Solution
- Use Docker volumes to persist Claude's configuration
- Pre-configure settings to skip setup prompts
- Link persistent storage to Claude's expected locations

## Quick Start

### 1. Build the Persistent Image
```bash
cd /Users/abhishek/Work/claude-docker-automation
docker build -f Dockerfile.persistent -t claude-persistent:latest .
```

### 2. First Run (Creates Persistent Volume)
```bash
./claude-docker-persistent.sh start /Users/abhishek/Work/coin-flip-app
```

On first run:
- Creates a Docker volume named `claude-config-volume`
- Pre-configures Claude settings to skip setup
- Copies your authentication to persistent storage

### 3. Subsequent Runs (No More Setup!)
```bash
./claude-docker-persistent.sh start /Users/abhishek/Work/coin-flip-app
```

Subsequent runs will:
- Use the existing configuration
- Skip theme selection
- Skip login prompts
- Start directly with your previous settings

## Commands

### Start with Persistent Config
```bash
./claude-docker-persistent.sh start [project-path]
```

### Check Volume Status
```bash
./claude-docker-persistent.sh info
```

### Reset Configuration (Start Fresh)
```bash
./claude-docker-persistent.sh reset
```

## How It Works

1. **Docker Volume**: Creates `claude-config-volume` to store:
   - `~/.claude/` directory (settings, preferences)
   - `~/.config/` directory (additional config)
   - `.claude.json` (authentication)

2. **Pre-Configuration**: On first run, creates:
   ```json
   {
     "setupComplete": true,
     "firstRun": false,
     "hasShownWelcome": true,
     "theme": "dark"
   }
   ```

3. **Symlinks**: Links persistent storage to expected locations:
   - `/home/claude/.claude-persistent/.claude` → `/home/claude/.claude`
   - `/home/claude/.claude-persistent/.config` → `/home/claude/.config`

## Testing the Solution

### Test 1: Verify Persistence
```bash
# First run - will create volume
./claude-docker-persistent.sh start /Users/abhishek/Work/coin-flip-app
# Exit Claude (Ctrl+D or 'exit')

# Second run - should skip setup!
./claude-docker-persistent.sh start /Users/abhishek/Work/coin-flip-app
# You should NOT see theme selection or login prompts
```

### Test 2: Check Volume
```bash
./claude-docker-persistent.sh info
# Should show volume exists with configuration files
```

### Test 3: Direct Docker Run (Alternative)
```bash
# Create volume manually
docker volume create claude-config-volume

# Run with volume
docker run -it --rm \
  -v claude-config-volume:/home/claude/.claude-persistent \
  -v "$HOME/.claude.json:/home/claude/.claude.json.host:ro" \
  -v "$(pwd):/workspace" \
  -w /workspace \
  claude-persistent:latest \
  claude --dangerously-skip-permissions
```

## Troubleshooting

### If Setup Still Appears
1. Reset the volume:
   ```bash
   ./claude-docker-persistent.sh reset
   ```

2. Check if Claude is finding the config:
   ```bash
   docker run --rm -v claude-config-volume:/check alpine ls -la /check/.claude/
   ```

3. Ensure you're using the persistent image:
   ```bash
   docker images | grep claude-persistent
   ```

### Manual Volume Inspection
```bash
# Find volume location
docker volume inspect claude-config-volume

# Check contents (on Mac, might need to access through Docker VM)
docker run --rm -v claude-config-volume:/data alpine ls -la /data/
```

## Benefits
- ✅ No more setup prompts on every run
- ✅ Maintains your theme preferences
- ✅ Keeps authentication between sessions
- ✅ Preserves any Claude settings/preferences
- ✅ Works across different projects

## Next Steps
1. Build the persistent image
2. Try the persistent launcher
3. Verify setup only happens once
4. Enjoy seamless Claude sessions!

The key insight is that Claude Code needs its configuration directory to persist between container runs. This solution provides that persistence while maintaining security and isolation.