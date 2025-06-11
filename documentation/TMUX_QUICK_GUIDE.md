# 🎯 Quick tmux Navigation Guide

## Your Current Windows:

1. dashboard - Monitor view
2. palladio-191408 - Palladio project (2 hours old)
3. work-070959 - Work directory (15 hours old)
4. work-030125 - Work directory (19 hours old)
5. work-161317 - Work directory (30 hours old)
6. palladio-155426 - Palladio project (30 hours old)
7. claude-bob - Collaboration bot
8. claude-alice - Collaboration bot
9. automation-145822 - Docker automation
10. test-web - Test project
11. test-web - Test project
12. palladio-215205 - Palladio project (2 days old)

## Essential Commands (memorize these!):

### Navigate:
- `Ctrl-b w` - **LIST ALL WINDOWS** (best method!)
- `Ctrl-b n` - Next window
- `Ctrl-b p` - Previous window
- `Ctrl-b 2` - Jump to window 2 (palladio-191408)
- `Ctrl-b 7` - Jump to window 7 (claude-bob)

### In Each Window:
- `Enter` - Attach to that Docker container
- `Ctrl-p Ctrl-q` - Detach from Docker (safe)
- `Ctrl-c` - DON'T USE (kills the container)

### tmux Control:
- `Ctrl-b d` - Detach from tmux (leave running)
- `Ctrl-b [` - Scroll mode (use arrows, q to exit)
- `Ctrl-b &` - Kill current window (careful!)

## What to Do Now:

1. Press `Ctrl-b w` to see all your windows
2. Use arrows to highlight the one you want
3. Press Enter to switch to it
4. Press Enter again to attach to that Docker session

## Color Coding:
- Right-click any pane → "Change Profile" → Select:
  - Palladio (blue) for palladio windows
  - Work (green) for work windows
  - Automation (red) for automation windows