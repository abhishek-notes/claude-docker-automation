# Complete Technical Overview: Claude Code Docker + tmux + iTerm2 Setup

## 1. The Architecture

### What We're Running
- **11 Claude Code instances** running in separate Docker containers
- Each container runs Claude Code (an AI coding assistant) in an isolated environment
- Containers are named like: `claude-session-palladio-software-25-20250608-191408`, `claude-session-Work-20250608-070959`, etc.

### The Docker Setup
```bash
# Each Claude Code instance runs in Docker like this:
docker run --rm \
  --name claude-session-[project]-[timestamp] \
  -v /path/to/project:/workspace \
  ghcr.io/anthropics/claude-code:latest \
  claude --dangerously-skip-permissions
```

### The tmux Layer
- **Purpose**: Session persistence - if terminal crashes, Claude keeps running
- **Structure**: One tmux session "claude-main" with 12 windows:
  - Window 0: Dashboard (monitoring script)
  - Windows 1-11: Each connected to a Docker container

### The Problem We're Solving
When terminal crashes or we close iTerm, we want to:
1. Reconnect to all 11 Claude sessions
2. See each in a separate tab
3. Preserve conversation history
4. Have proper color coding

## 2. How the Migration Works

### Step 1: Docker → tmux
The migration script creates tmux windows for each container:
```bash
# For each Docker container
for container in $(docker ps --filter name=claude); do
  # Create a tmux window
  tmux new-window -n "$container"
  # Set up the window to connect to Docker
  tmux send-keys "docker exec -it $container /bin/bash"
done
```

### Step 2: The Dashboard Problem
Window 0 runs an aggressive refresh loop:
```bash
while true; do
  clear
  docker ps --filter name=claude  # Shows container list
  sleep 2
done
```

This causes the "all tabs show same content" issue because:
- New tmux clients connect to the "active window" (usually 0)
- Dashboard's constant refresh overwrites everything

## 3. The Solution: How claude-open.sh Works

### The Core Concept: Session Cloning
```bash
# Original session with shared windows
claude-main
├── window 0: dashboard
├── window 1: palladio-191408
├── window 2: work-070959
└── ... 

# Create "clone sessions" that share windows but have independent pointers
claude-main-1 → points to window 1
claude-main-2 → points to window 2
claude-main-3 → points to window 3
```

### Step-by-Step Script Execution

1. **Check Base Session Exists**
```bash
tmux has-session -t "claude-main" || exit 1
```

2. **Loop Through Windows**
```bash
tmux list-windows -t "claude-main" -F "#{window_index} #{window_name}"
# Output:
# 0 dashboard
# 1 palladio-191408
# 2 work-070959
# ...
```

3. **Skip Dashboard, Process Others**
```bash
[[ "$idx" == "0" ]] && continue  # Skip window 0
```

4. **Find Matching Docker Container**
```bash
# Window name: "palladio-191408"
# Find container with similar name:
container=$(docker ps --filter name="$name" --format '{{.Names}}')
# Returns: claude-session-palladio-software-25-20250608-191408
```

5. **Create Clone Session**
```bash
newsess="claude-main-${idx}"  # e.g., "claude-main-1"
tmux new-session -d -s "$newsess" -t "claude-main:$idx"
```
This creates a new session that:
- Shares the same window/pane content
- Has its own "current window" pointer
- Solves the "all tabs show same" problem

6. **Auto-Attach to Docker**
```bash
tmux send-keys -t "$newsess:0.0" \
  "docker exec -it $container /bin/bash" C-m
```
This sends the docker exec command to the pane

7. **Open iTerm2 Tab**
```applescript
tell application "iTerm"
  create tab with profile "Palladio"  # Color coding
  tell current session
    set name to "palladio-191408"    # Tab title
    write text "tmux attach -t claude-main-1"
  end tell
end tell
```

## 4. The Complete Flow

### When You Run `ca`:

1. **Script starts**: `~/Work/claude-open.sh`

2. **Finds 11 Claude windows** (skips dashboard)

3. **For each window**:
   - Creates a clone session (e.g., `claude-main-1`)
   - Finds matching Docker container
   - Sends `docker exec -it [container] /bin/bash`
   - Opens new iTerm tab with correct color
   - Attaches tab to clone session

4. **Result**: 11 iTerm tabs, each showing different Claude session

## 5. Why This Works

### Problem: One Session = One Current Window
```
Traditional approach (FAILS):
Tab 1: tmux attach -t claude-main:1  → Shows window 0 (dashboard)
Tab 2: tmux attach -t claude-main:2  → Shows window 0 (dashboard)
Tab 3: tmux attach -t claude-main:3  → Shows window 0 (dashboard)
```

### Solution: Separate Sessions = Separate Current Windows
```
Clone session approach (WORKS):
Tab 1: tmux attach -t claude-main-1  → Shows window 1
Tab 2: tmux attach -t claude-main-2  → Shows window 2
Tab 3: tmux attach -t claude-main-3  → Shows window 3
```

## 6. The Goal

**Create a single command (`ca`) that**:
1. Opens 11 iTerm2 tabs
2. Each tab shows a different Claude Code session
3. Each tab is already connected to its Docker container
4. Preserves all conversation history (10,000+ lines)
5. Uses proper color profiles (Palladio=blue, Work=green, etc.)
6. Works reliably without the dashboard overwriting everything

## 7. Current Status

- ✅ Script creates separate sessions (solves main problem)
- ✅ Finds correct Docker containers
- ✅ Auto-attaches to containers
- ✅ Opens tabs with correct profiles
- ✅ Each tab shows different content
- ❓ Need to verify: Full conversation history visible
- ❓ Need to verify: No residual issues from migration

## 8. The Technical Challenge

The core challenge was that tmux's architecture assumes one "current window" per session, but iTerm2's tab interface expects each tab to show different content. The clone session trick bridges this gap by creating lightweight sessions that share underlying windows but maintain independent view states.