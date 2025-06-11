#!/usr/bin/env bash
# claude-open.sh - Attach to all Claude tmux windows in separate iTerm2 tabs.
# Solves the "all tabs show the same content" issue by using the 
# "Session Cloning" technique.

set -e # Exit immediately if a command exits with a non-zero status.

MASTER_SESSION="claude-main"
CLONE_PREFIX="${MASTER_SESSION}-"

# --- 1. Pre-flight Checks ---
if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed."
    exit 1
fi

if ! tmux has-session -t "$MASTER_SESSION" 2>/dev/null; then
    echo "Error: Master tmux session '$MASTER_SESSION' not found."
    echo "Please start the main Claude session first."
    exit 1
fi

# --- 2. Cleanup Stale Clones ---
# Before creating new clones, kill any that might be left over from a previous run.
echo "Cleaning up old clone sessions..."
tmux list-sessions -F '#{session_name}' | grep "^${CLONE_PREFIX}" | xargs -I {} tmux kill-session -t {} || true

# --- 3. Create iTerm2 Window and Prepare for Tabs ---
# This AppleScript creates a new window and returns its ID so we can add tabs to it.
WINDOW_ID=$(osascript <<'EOF'
tell application "iTerm2"
    create window with default profile
    return id of current window
end tell
EOF
)

echo "Created new iTerm2 window with ID: $WINDOW_ID"

# --- 4. Main Loop: Iterate Through Windows and Create Clones/Tabs ---
echo "Processing tmux windows and creating iTerm tabs..."

tmux list-windows -t "$MASTER_SESSION" -F "#{window_index} #{window_name}" | while read -r idx name; do
    # Skip the dashboard window
    if [[ "$idx" == "0" ]]; then
        echo "  -> Skipping dashboard (window 0)..."
        continue
    fi
    
    echo "  -> Processing window $idx: $name"
    
    # a. Define names for the clone session and iTerm tab
    CLONE_SESSION_NAME="${CLONE_PREFIX}${idx}"
    TAB_TITLE="$name"
    
    # b. Determine iTerm profile based on window name for color-coding
    PROFILE="Default" # Default profile
    if [[ "$name" == *"palladio"* ]]; then
        PROFILE="Palladio" # Assumes you have a profile named "Palladio"
    elif [[ "$name" == *"work"* ]]; then
        PROFILE="Work"     # Assumes you have a profile named "Work"
    fi
    echo "     - Using profile: $PROFILE"
    
    # c. Create the clone session, linking to the correct window
    echo "     - Creating clone session: $CLONE_SESSION_NAME -> $MASTER_SESSION:$idx"
    tmux new-session -d -s "$CLONE_SESSION_NAME" -t "$MASTER_SESSION:$idx"
    
    # d. Use AppleScript to create and configure the iTerm tab
    osascript <<EOF
tell application "iTerm2"
    tell window id "$WINDOW_ID"
        create tab with profile "$PROFILE"
        tell current session
            -- Set tab title
            set name to "$TAB_TITLE"
            
            -- Attach to the unique clone session
            write text "tmux attach -t \"$CLONE_SESSION_NAME\""
        end tell
    end tell
end tell
EOF

done

# --- 5. Final Step ---
# Bring iTerm2 to the front. The first tab might be a blank "Default" profile tab;
# you can close it manually.
osascript -e 'tell application "iTerm2" to activate'

echo ""
echo "✅ Done. All Claude sessions are open in their respective tabs."