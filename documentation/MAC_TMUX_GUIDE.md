# 🍎 tmux on Mac - Quick Reference

## IMPORTANT: It's Ctrl, not Cmd!

On Mac, tmux uses **Ctrl** (not Cmd) for all commands:
- ✅ `Ctrl-b` - tmux prefix 
- ❌ `Cmd-b` - this does something else in iTerm2

## Complete Navigation Guide

### Inside Docker Container (Claude Code):
When you see the `>` prompt:
- `Ctrl-p` then `Ctrl-q` - Detach from Docker container
- After detaching, you'll see: "Session detached. This window will stay open."

### In tmux (after detaching from Docker):
Now you can use tmux commands:
- `Ctrl-b w` - List all windows (best navigation method!)
- `Ctrl-b n` - Next window
- `Ctrl-b p` - Previous window
- `Ctrl-b 1` - Go to window 1
- `Ctrl-b 2` - Go to window 2 (etc.)
- `Ctrl-b d` - Detach from tmux entirely

### iTerm2 Tab Navigation (uses Cmd):
- `Cmd-1, Cmd-2...` - Switch between iTerm tabs
- `Cmd-Shift-[` - Previous tab
- `Cmd-Shift-]` - Next tab
- `Cmd-w` - Close tab

## Your Updated Commands:

```bash
ca          # Opens ALL sessions in separate tabs (NEW DEFAULT!)
ca single   # Opens tmux in single window (old behavior)
ca s        # Shortcut for ca single

ca p        # Open all Palladio sessions in tabs
ca w        # Open all Work sessions in tabs
ca a        # Open all Automation sessions in tabs
```

## Visual: What Uses What?

```
iTerm2 tabs:    Cmd-1, Cmd-2, Cmd-w           (Apple/Mac standard)
tmux windows:   Ctrl-b w, Ctrl-b n, Ctrl-b d  (Linux/Unix standard)
Docker detach:  Ctrl-p Ctrl-q                 (Docker standard)
```

## Step-by-Step Example:

1. You're in Claude Code (`>` prompt)
2. Press `Ctrl-p` then `Ctrl-q` to detach
3. You see "Session detached. This window will stay open."
4. Now press `Ctrl-b w` to see all windows
5. Use arrows to select, Enter to switch
6. Press Enter again to re-attach to Docker

Remember: tmux is a Linux tool, so it always uses Ctrl, even on Mac!