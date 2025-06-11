#!/bin/bash

# Fix the dashboard window to not use 'watch' command

TMUX_SESSION="claude-main"

echo "Fixing dashboard window..."

# Send Ctrl-C to stop watch, then use a while loop instead
tmux send-keys -t "$TMUX_SESSION:0" C-c
sleep 1

tmux send-keys -t "$TMUX_SESSION:0" "
while true; do
  clear
  echo -e '\\033[1;36m🤖 Claude Docker Sessions\\033[0m'
  echo ''
  docker ps --filter name=claude --format 'table {{.Names}}\t{{.Status}}' | head -20
  echo ''
  echo 'Updated: '\$(date)
  echo 'Press Ctrl-C to stop'
  sleep 2
done
" Enter

echo "✅ Dashboard fixed to use shell loop instead of 'watch'"