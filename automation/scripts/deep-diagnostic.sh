#!/bin/bash

# Comprehensive diagnostic script

echo "=== CLAUDE DOCKER + TMUX DIAGNOSTIC ==="
echo "Time: $(date)"
echo ""

# 1. Test manual window switching
echo "1. TESTING MANUAL WINDOW SWITCHING:"
echo "   Please run these commands in separate terminal tabs:"
echo "   Tab 1: tmux attach -t claude-main \\; select-window -t 1"
echo "   Tab 2: tmux attach -t claude-main \\; select-window -t 2"
echo "   Question: Do they show DIFFERENT content?"
echo ""

# 2. Check what's actually in the Docker containers
echo "2. DOCKER CONTAINER INSPECTION:"
for container in $(docker ps --filter name=claude --format '{{.Names}}' | head -3); do
  echo "Container: $container"
  echo "  Running process:"
  docker exec $container ps aux | grep -v "ps aux" | tail -3
  echo "  Is Claude running?"
  docker exec $container pgrep -f claude || echo "  No claude process found"
  echo ""
done

# 3. Check tmux pane content in detail
echo "3. TMUX PANE CONTENT (first 10 lines of each window):"
for i in {1..3}; do
  echo "Window $i:"
  tmux capture-pane -t claude-main:$i -p -S -10 | head -10
  echo "---"
done

# 4. Test creating a fresh minimal session
echo "4. TESTING FRESH SESSION APPROACH:"
TEST_SESSION="test-claude"
tmux kill-session -t $TEST_SESSION 2>/dev/null || true

# Create test session with 3 windows
tmux new-session -d -s $TEST_SESSION
tmux new-window -t $TEST_SESSION:1
tmux new-window -t $TEST_SESSION:2

# Send different content to each
tmux send-keys -t $TEST_SESSION:0 "echo 'This is window 0'" C-m
tmux send-keys -t $TEST_SESSION:1 "echo 'This is window 1'" C-m
tmux send-keys -t $TEST_SESSION:2 "echo 'This is window 2'" C-m

# Create clone sessions
for i in {0..2}; do
  tmux new-session -d -s "${TEST_SESSION}-${i}" -t "${TEST_SESSION}:${i}"
done

echo "Created test sessions. Try:"
echo "  Terminal 1: tmux attach -t test-claude-0"
echo "  Terminal 2: tmux attach -t test-claude-1"
echo "  Terminal 3: tmux attach -t test-claude-2"
echo "Do these show different content?"
echo ""

# 5. Check if we're dealing with nested tmux
echo "5. CHECKING FOR NESTED TMUX:"
for i in {1..3}; do
  echo "Window $i environment:"
  tmux send-keys -t claude-main:$i "echo \$TMUX" C-m
  sleep 0.5
  tmux capture-pane -t claude-main:$i -p | tail -3
done

# 6. The real issue might be...
echo ""
echo "6. HYPOTHESIS:"
echo "All windows might be showing the SAME Docker container's Claude instance."
echo "Let's check which container each window is connected to:"
echo ""

for i in {1..3}; do
  echo "Window $i:"
  tmux send-keys -t claude-main:$i C-m  # Send enter in case needed
  sleep 0.5
  tmux send-keys -t claude-main:$i "hostname" C-m
  sleep 0.5
  tmux capture-pane -t claude-main:$i -p | grep -E "(hostname|claude@)" | tail -2
done

echo ""
echo "=== END DIAGNOSTIC ==="