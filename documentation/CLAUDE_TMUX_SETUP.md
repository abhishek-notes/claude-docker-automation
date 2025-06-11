# Claude Docker + tmux Setup Guide

## Quick Start Commands

### 1. Reload your shell to get the new aliases:
```bash
source ~/.zshrc
```

### 2. Migrate all your existing Claude sessions to tmux:
```bash
~/Work/migrate-all-claude-sessions.sh
```

### 3. Your new aliases:
- `claude` - Claude session manager
- `ca` - Attach to Claude tmux session
- `claude-daily` - Start your task API server
- `claude-task` - Launch new Claude tasks
- `claude-list` - List all active Claude windows

### 4. Key tmux shortcuts (memorize these!):
- `Ctrl-b w` - List all windows (use arrows to select)
- `Ctrl-b d` - Detach (leave everything running)
- `Ctrl-b [` - Scroll mode (q to exit)
- `Ctrl-b n/p` - Next/Previous window
- `Ctrl-b 0-9` - Jump to window by number

### 5. Daily workflow:
```bash
# Start your task server (opens at localhost:3456)
claude-daily

# All tasks from the web UI will now open in the same tmux session!

# Check what's running
claude-list

# Attach to see everything
ca

# Launch specific task manually
claude-task start ~/Work/my-project
```

## Benefits of this setup:
✅ All Claude sessions in one tmux session (multiple windows, not multiple terminal windows)
✅ Terminal/iTerm can crash - everything keeps running
✅ Easy navigation with Ctrl-b w
✅ Each session shows its recent activity before attaching
✅ Color-coded dashboard shows all running containers

## If iTerm crashes:
1. Just reopen iTerm
2. Run: `ca` (or `tmux attach -t claude-main`)
3. Everything is exactly where you left it!