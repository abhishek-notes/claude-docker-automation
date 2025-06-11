#!/bin/bash

# Alternative approach: Use separate tmux sessions for different project types
# This keeps things more organized when you have MANY tasks

launch_claude_separate_session() {
    local project_path="${1:-$(pwd)}"
    local task_file="${2:-CLAUDE_TASKS.md}"
    local task_name="${3:-$(basename "$project_path")}"
    
    # Determine which tmux session based on project type
    if [[ "$project_path" == *"palladio"* ]]; then
        TMUX_SESSION="claude-palladio"
        profile="Palladio"
    elif [[ "$project_path" == *"automation"* ]]; then
        TMUX_SESSION="claude-automation"
        profile="Automation"
    else
        TMUX_SESSION="claude-work"
        profile="Work"
    fi
    
    # Create session if it doesn't exist
    if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        tmux new-session -d -s "$TMUX_SESSION" -n "dashboard"
    fi
    
    # Continue with normal launch...
    echo "Launching in session: $TMUX_SESSION"
}

# Add to your .zshrc:
# alias cap="tmux attach -t claude-palladio"  # Attach to Palladio sessions
# alias caw="tmux attach -t claude-work"      # Attach to Work sessions
# alias caa="tmux attach -t claude-automation" # Attach to Automation sessions