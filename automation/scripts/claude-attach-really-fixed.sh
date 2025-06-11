#!/usr/bin/env bash
# Fixed version that properly selects different windows

SESSION="claude-main"

# First, close all existing tabs to clean up
echo "🧹 Cleaning up existing connections..."
tmux kill-session -t temp-1 2>/dev/null || true
tmux kill-session -t temp-2 2>/dev/null || true
tmux kill-session -t temp-3 2>/dev/null || true
tmux kill-session -t temp-4 2>/dev/null || true
tmux kill-session -t temp-5 2>/dev/null || true
tmux kill-session -t temp-6 2>/dev/null || true
tmux kill-session -t temp-7 2>/dev/null || true
tmux kill-session -t temp-8 2>/dev/null || true
tmux kill-session -t temp-9 2>/dev/null || true
tmux kill-session -t temp-10 2>/dev/null || true
tmux kill-session -t temp-11 2>/dev/null || true

# Map tmux-window-name substrings → iTerm2 profile name
profile_for() {
  case "$1" in
    palladio*) echo "Palladio" ;;
    work*)     echo "Work" ;;
    automation*|cleaner*) echo "Automation" ;;
    claude-bob|claude-alice) echo "Work" ;;
    *)         echo "Default" ;;
  esac
}

echo "🎨 Opening color-coded tabs for all Claude sessions..."

# Create new iTerm window
/usr/bin/osascript <<'EOF'
tell application "iTerm"
  create window with default profile
end tell
EOF

sleep 1

# Get list EXCLUDING dashboard (window 0)
tmux list-windows -t "$SESSION" -F "#{window_index} #{window_name}" | grep -v "^0 " |
while read -r idx name; do
  profile=$(profile_for "$name")
  echo "  Opening tab for window $idx: $name (Profile: $profile)"

  # Use different command that actually switches windows
  /usr/bin/osascript <<EOF
tell application "iTerm"
  tell current window
    create tab with profile "$profile"
    tell current session
      -- This command creates a new session linked to specific window
      write text "tmux new-session -d -s temp-$idx -t $SESSION:$idx && tmux attach-session -t temp-$idx"
    end tell
  end tell
end tell
EOF
  
  sleep 0.5
done

echo ""
echo "✅ Opened all Claude windows!"
echo ""
echo "Each tab is now showing a different tmux window."
echo "Press Enter in any tab to attach to that Docker container."