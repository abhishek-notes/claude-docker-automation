#!/bin/zsh

# --- Configuration ---
SESSION_NAME="claude-main"

# --- 1. Clean Slate: Kill any pre-existing session ---
# This ensures we start fresh and avoid conflicts.
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
  echo "Killing existing tmux session: $SESSION_NAME"
  tmux kill-session -t $SESSION_NAME
fi

# --- 2. Create the Session (Detached) and Dashboard Window ---
# The -d flag is CRITICAL. It creates the session without attaching,
# preventing it from becoming the "active" session in any terminal.
echo "Creating new session '$SESSION_NAME' with dashboard..."
tmux new-session -d -s $SESSION_NAME -n dashboard \
  'while true; do
    clear
    echo -e "\033[1;36m🤖 Claude Docker Sessions\033[0m"
    echo ""
    docker ps --filter name=claude --format "table {{.Names}}\t{{.Status}}" | head -20
    echo ""
    echo "Updated: $(date)"
    echo "Press Ctrl-C to stop"
    sleep 2
  done'

# --- 3. Find Docker Containers and Create a Window for Each ---
echo "Finding Claude containers and creating windows..."
# Use an array to handle names with spaces, just in case.
CONTAINERS=($(docker ps --filter name=claude --format '{{.Names}}'))

if [ ${#CONTAINERS[@]} -eq 0 ]; then
  echo "Error: No Docker containers with name 'claude' found. Aborting."
  tmux kill-session -t $SESSION_NAME
  exit 1
fi

# Counter for window numbering
window_num=1
for container in "${CONTAINERS[@]}"; do
  echo "  -> Creating window $window_num for: $container"
  
  # Determine window name (shortened if needed)
  if [[ $container == *"palladio"* ]]; then
    window_name="palladio-$window_num"
  elif [[ $container == *"work"* ]]; then
    window_name="work-$window_num"
  elif [[ $container == *"automation"* ]]; then
    window_name="automation-$window_num"
  else
    window_name="${container:0:20}"  # Truncate long names
  fi
  
  # Create a new window in the target session
  tmux new-window -t "$SESSION_NAME" -n "$window_name"
  
  # Send command to show session info and attach option
  tmux send-keys -t "$SESSION_NAME:$window_num" "echo '📦 Container: $container'" C-m
  tmux send-keys -t "$SESSION_NAME:$window_num" "echo '🔗 Window $window_num in tmux session $SESSION_NAME'" C-m
  tmux send-keys -t "$SESSION_NAME:$window_num" "echo ''" C-m
  tmux send-keys -t "$SESSION_NAME:$window_num" "echo 'Press Enter to attach to Docker container:'" C-m
  tmux send-keys -t "$SESSION_NAME:$window_num" "docker exec -it $container /bin/bash"
  
  ((window_num++))
done

# --- 4. Select a "Quiet" Window as the Default ---
# This is a crucial hardening step. Before attaching, we explicitly
# make a non-dashboard window the active one. This makes the session
# state clean for any type of future attachment.
echo "Setting default window to first Claude session..."
tmux select-window -t "$SESSION_NAME:1"

# --- 5. Attach with iTerm2 Control Mode ---
# Now that the entire session is perfectly constructed in the background,
# we can attach. iTerm2 will read the complete window list and correctly
# display each one in its own tab.
echo ""
echo "✅ All windows created successfully!"
echo "   Dashboard: 1 window"
echo "   Claude sessions: ${#CONTAINERS[@]} windows"
echo ""
echo "Attaching with iTerm2 Control Mode..."
tmux -CC attach-session -t $SESSION_NAME