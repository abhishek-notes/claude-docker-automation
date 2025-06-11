# Complete Context: Claude Docker + tmux + iTerm2 Setup Journey

## Background Story
I'm running multiple Claude Code instances in Docker containers for different projects. My terminal app crashed, and I was worried about losing my sessions. I asked Claude for help setting up a more robust system.

## What We Built Together

### 1. Initial Problem
- Using macOS Terminal app
- Running multiple Claude Code Docker containers with automated scripts
- Terminal GUI crashed, was worried about losing sessions
- Had 11 active Claude Docker containers running

### 2. Solution Implemented
Claude helped me set up:
- **Switched to iTerm2** (installed via homebrew)
- **Installed tmux** for session persistence
- **Created iTerm2 profiles**: "Palladio" (blue tint), "Work" (green tint), "Automation" (red tint)
- **Built migration script** that moves all Docker containers to tmux windows

### 3. Scripts Created
1. `claude-manager.sh` - General session management
2. `migrate-all-claude-sessions-enhanced.sh` - Migrates Docker containers to tmux with 10,000 lines of history
3. `claude-attach-enhanced.sh` - Should open all sessions in tabs (this is broken)
4. Various other helper scripts

### 4. Aliases Set Up
```bash
alias cm="~/Work/claude-manager.sh"          # Claude Manager
alias ca="~/Work/claude-attach-enhanced.sh"  # Should open all in tabs (broken)
alias claude-daily="cd ~/Work/claude-docker-automation && ./start-system.sh"
alias claude-task="cd ~/Work/claude-docker-automation && ./claude-direct-task.sh"
alias claude-list="tmux list-windows -t claude-main 2>/dev/null"
```

### 5. Current State
- ✅ All 11 Docker containers migrated to tmux successfully
- ✅ Can navigate using `tmux attach -t claude-main` then `Ctrl-b w`
- ✅ Each window shows proper history (10,000 lines analyzed)
- ❌ Cannot open all windows in separate iTerm2 tabs

## The Specific Problem

### What Works
1. Single window tmux mode:
```bash
tmux attach -t claude-main  # Works perfectly
Ctrl-b w                    # Shows all 11 windows
```

2. tmux structure is correct:
```
Window 0: dashboard
Window 1: palladio-191408 → claude-session-palladio-software-25-20250608-191408
Window 2: work-070959 → claude-session-Work-20250608-070959
Window 3: work-030125 → claude-session-Work-20250608-030125
Window 4: work-161317 → claude-session-Work-20250607-161317
Window 5: palladio-155426 → claude-session-palladio-software-25-20250607-155426
Window 6: claude-bob → claude-bob
Window 7: claude-alice → claude-alice
Window 8: automation-145822 → claude-session-claude-docker-automation-20250607-145822
Window 9: test-web → claude-session-test-web-claude-20250607-032259
Window 10: test-web → claude-session-test-web-claude-20250607-031020
Window 11: palladio-215205 → claude-session-palladio-software-25-20250606-215205
```

### What Doesn't Work
The `ca` command should open all 11 windows in separate iTerm2 tabs, but:

1. **AppleScript Syntax Errors**:
   - "Expected end of line, etc. but found property"
   - "syntax error: Expected """ but found unknown token"
   - Script says "✅ All sessions opened" but no tabs appear

2. **When Partially Working**:
   - All tabs show the same tmux window (window 0/dashboard)
   - Numbers 1-11 get typed into Claude Code prompt instead of tmux
   - Creates weird dotted lines in the terminal
   - Window gets resized incorrectly

3. **Root Issues**:
   - tmux commands with semicolons don't work in AppleScript write text
   - Keyboard input goes to Docker container (Claude Code) instead of tmux
   - Can't figure out proper escaping for compound tmux commands

## Attempted Solutions That Failed

1. **Direct tmux command approach**:
```applescript
write text "tmux attach -t claude-main \\; select-window -t 1"
```
Result: Syntax errors or semicolon gets interpreted wrong

2. **System Events keyboard approach**:
```applescript
tell application "System Events"
    key code 11 using control down -- Ctrl-b
    keystroke "1"
end tell
```
Result: Numbers typed into Claude Code, not tmux

3. **Sequential commands**:
```applescript
write text "tmux attach -t claude-main"
delay 2
write text "1"
```
Result: "1" typed into Claude Code interface

4. **Using && instead of ;**:
```applescript
write text "tmux attach -t claude-main && tmux select-window -t 1"
```
Result: Second command runs after detaching from tmux

## What I Need
A working script that:
1. Opens iTerm2 with 11 tabs
2. Each tab shows its corresponding tmux window (1-11)
3. Proper iTerm2 profiles applied (Palladio=blue, Work=green, Automation=red)
4. No AppleScript syntax errors
5. Proper tmux window selection without typing into Docker containers
6. **IMPORTANT**: Each tmux window should show the session history with up to 10,000 lines of previous Claude Code conversation, not just a blank prompt

## Additional Issue: Session History Not Showing
When attaching to tmux windows, I should see the previous conversation history with Claude Code (up to 10,000 lines), but sometimes I just see a blank prompt or limited history. The migration script is set to analyze 10,000 lines:

```bash
docker logs --tail 10000 "$container" 2>&1
```

But when opening tabs, the history doesn't always appear properly. Each session should show what Claude was working on previously.

## Constraints for ChatGPT
**IMPORTANT**: ChatGPT does NOT have:
- MCP (Model Context Protocol) access
- Direct file system access
- Ability to run commands

So the response should be:
- Complete code blocks that I can copy and run
- Clear explanations in chat format
- No attempts to directly execute or test anything
- Step-by-step instructions if needed

## Environment Details
- macOS (M3 Max)
- iTerm2 Build 3.5.14
- tmux 3.5a
- zsh shell
- Docker Desktop
- Claude Code running in containers

## Key Insight from Testing
The main issue seems to be that when we attach to tmux, we're immediately in the Docker container (Claude Code), so any subsequent input goes to Claude, not to tmux. We need a way to either:
1. Select the tmux window BEFORE attaching, or
2. Attach to a specific window directly, or
3. Use iTerm2's tmux integration mode

Please provide a complete, working solution that solves these issues!