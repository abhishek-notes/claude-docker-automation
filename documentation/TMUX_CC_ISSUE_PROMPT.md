# Complete Context: tmux -CC Shows Dashboard in All Tabs Issue

## Background
I have 11 Claude Code instances running in Docker containers on macOS. I successfully set up tmux with all containers in separate windows. Everything works fine when navigating manually with `tmux attach -t claude-main` and then `Ctrl-b w`.

## Current Setup That Works
- 11 Docker containers running Claude Code
- tmux session "claude-main" with 12 windows:
  - Window 0: dashboard (monitoring script)
  - Windows 1-11: Individual Claude sessions
- Manual navigation works perfectly with `Ctrl-b w`
- Each window has proper session history

## The Problem
When using `tmux -CC attach -t claude-main` (iTerm2's native tmux integration):
- iTerm2 creates tabs for each tmux window ✓
- Tab names are correct (dashboard, palladio-191408, work-070959, etc.) ✓
- **BUT: Every single tab shows the same content - the dashboard (window 0)**
- All tabs display the Docker container list that updates every 2 seconds
- Cannot see the actual Claude sessions in windows 1-11

## What's Happening
Dashboard (window 0) runs this loop:
```bash
while true; do
  clear
  echo -e '\033[1;36m🤖 Claude Docker Sessions\033[0m'
  echo ''
  docker ps --filter name=claude --format 'table {{.Names}}\t{{.Status}}' | head -20
  echo ''
  echo 'Updated: '$(date)
  echo 'Press Ctrl-C to stop'
  sleep 2
done
```

This is what appears in EVERY tab, even though tabs are labeled correctly.

## Debugging Info
```bash
# This shows windows exist correctly:
tmux list-windows -t claude-main
0: dashboard (active: 1)
1: palladio-191408 (active: 0)
2: work-070959 (active: 0)
...
11: palladio-215205 (active: 0)

# Multiple clients attached to same session:
tmux list-clients
/dev/ttys035: claude-main [214x49 xterm-256color] (attached,focused,UTF-8)
/dev/ttys036: claude-main [214x49 xterm-256color] (attached,focused,UTF-8)
...
/dev/ttys045: claude-main [214x49 xterm-256color] (attached,focused,UTF-8)
```

## What I've Tried
1. Basic `tmux -CC attach -t claude-main` - All tabs show dashboard
2. Detaching all clients first - Same issue
3. Using different attach syntaxes - Same issue
4. Creating new tmux sessions linked to specific windows - Syntax errors
5. Manual window switching works fine, just not with -CC mode

## Environment
- macOS M3 Max
- iTerm2 Build 3.5.14
- tmux 3.5a
- Docker Desktop
- zsh shell

## The Question
How can I make `tmux -CC attach -t claude-main` properly show different windows in different tabs? Currently, all tabs show window 0 (dashboard) content, even though the tab names indicate they should show different windows.

Is this a bug in iTerm2's tmux integration? Or is there a specific way to use tmux -CC with pre-existing windows that I'm missing?

## Ideal Solution
When running `tmux -CC attach -t claude-main`:
- Tab 1 labeled "dashboard" shows the monitoring script ✓ 
- Tab 2 labeled "palladio-191408" shows window 1 content (Claude session)
- Tab 3 labeled "work-070959" shows window 2 content (Claude session)
- etc.

Currently, ALL tabs show the dashboard content despite correct labels.

## Alternative Approaches Welcome
If tmux -CC can't handle this properly, what's the best way to:
1. Open multiple iTerm2 tabs
2. Each tab attached to a different tmux window
3. Maintain the color profiles (Palladio=blue, Work=green, etc.)
4. See the full session history in each tab

Manual setup works but is tedious for 11 windows. Need an automated solution.