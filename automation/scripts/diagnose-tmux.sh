#!/bin/bash

# Diagnostic script to understand the tmux/Docker setup

echo "=== DIAGNOSTIC REPORT ==="
echo ""

# 1. Check tmux windows
echo "1. TMUX WINDOWS in claude-main:"
tmux list-windows -t claude-main -F "#I: #W (panes: #{window_panes})" 2>/dev/null || echo "No claude-main session"
echo ""

# 2. Check what's in each pane
echo "2. PANE CONTENTS:"
for i in {0..11}; do
  if tmux has-session -t claude-main:$i 2>/dev/null; then
    echo "Window $i:"
    tmux capture-pane -t claude-main:$i -p | grep -E "(>|docker exec|Container:|🔗)" | tail -5
    echo "---"
  fi
done
echo ""

# 3. Check Docker containers
echo "3. DOCKER CONTAINERS:"
docker ps --filter name=claude --format "{{.Names}} - {{.Command}}" | head -12
echo ""

# 4. Check clone sessions
echo "4. EXISTING CLONE SESSIONS:"
tmux list-sessions | grep "claude-main-"
echo ""

# 5. Test direct attachment
echo "5. TESTING DIRECT ATTACHMENT:"
echo "Try these commands manually:"
echo "  tmux attach -t claude-main:1  (should show window 1)"
echo "  tmux attach -t claude-main:2  (should show window 2)"
echo ""
echo "Do they show different content when run manually?"