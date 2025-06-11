# Complete Issue: Cannot Open Multiple tmux Windows in Separate iTerm2 Tabs

## Summary
I have 11 Claude Code Docker containers running. Each is attached to a tmux window (windows 1-11) in session "claude-main". Window 0 runs a dashboard monitoring script. When trying to open each window in a separate iTerm2 tab, ALL tabs show the same content (the dashboard from window 0) instead of their respective windows.

## Current Setup
- macOS M3 Max
- iTerm2 (tried both 3.5.14 stable and nightly @3.5.20241106)
- tmux 3.5a
- 11 Docker containers running Claude Code
- tmux session "claude-main" with 12 windows:
  - Window 0: dashboard (monitoring loop)
  - Windows 1-11: Individual Claude sessions

## The Dashboard Problem
Window 0 runs this aggressive refresh loop:
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

## What Happens
1. **Manual navigation works perfectly**:
   ```bash
   tmux attach -t claude-main
   # Then Ctrl-b w to select windows - each shows correct content
   ```

2. **All automated approaches fail** - every tab shows the dashboard:
   - `tmux -CC attach -t claude-main` - all tabs show dashboard
   - AppleScript creating tabs - all tabs show dashboard
   - Direct window attachment - all tabs show dashboard

## Failed Attempts

### Attempt 1: tmux -CC (Control Mode)
```bash
tmux -CC attach -t claude-main
```
Result: Creates tabs with correct names but ALL show dashboard content

### Attempt 2: Direct Window Attachment
```bash
# AppleScript approach
tell application "iTerm"
  create tab with profile "Work"
  tell current session
    write text "tmux attach -t claude-main:2"
  end tell
end tell
```
Result: Still shows dashboard in all tabs

### Attempt 3: Using select-window
```bash
write text "tmux attach-session -t claude-main \\; select-window -t 2"
```
Result: Command runs but window 0 content overwrites it immediately

### Attempt 4: New Session Per Window
```bash
tmux new-session -d -s temp-$idx -t claude-main:$idx
tmux attach -t temp-$idx
```
Result: Still shows dashboard

### Attempt 5: Stopping Dashboard First
```bash
# Stop the dashboard loop
tmux send-keys -t claude-main:0 C-c
# Then try to attach to other windows
```
Result: Dashboard stops but other windows STILL show dashboard content (cached?)

## Complete Script That Should Work But Doesn't
```bash
#!/bin/bash
SESSION="claude-main"

# Create new iTerm window
osascript <<'EOF'
tell application "iTerm"
  create window with default profile
end tell
EOF

# For each non-dashboard window
tmux list-windows -t "$SESSION" -F "#{window_index} #{window_name}" | grep -v "^0 " |
while read -r idx name; do
  osascript <<EOF
tell application "iTerm"
  tell current window
    create tab with default profile
    tell current session
      write text "tmux attach-session -t $SESSION \\; select-window -t $idx"
    end tell
  end tell
end tell
EOF
done
```

## The Core Problem
Even though:
- tmux windows exist and contain different content
- Manual navigation (Ctrl-b w) shows each window correctly
- Tab names are correct when created

ALL tabs display window 0 (dashboard) content, as if:
- The dashboard is somehow broadcasting to all panes
- Or tmux is confused about which window to display
- Or there's a race condition with the refresh loop

## What I Need
A working solution to:
1. Open iTerm2 with 11 tabs (skip dashboard)
2. Each tab shows its corresponding tmux window (1-11)
3. Each tab displays the actual Claude Code session content
4. NOT all showing the dashboard

## Environment Details
```bash
$ tmux -V
tmux 3.5a

$ echo $TERM
xterm-256color

$ tmux show-options -g | grep base-index
base-index 0

$ tmux list-clients | wc -l
12  # Multiple clients attached
```

## The Question
Why do all tabs/panes show window 0 content regardless of which window they're supposed to attach to? Is this a tmux bug, an iTerm2 issue, or something about how the dashboard's refresh loop interacts with tmux's display management?

Most importantly: How can I open multiple tmux windows in separate iTerm2 tabs where each tab actually shows its own window's content?