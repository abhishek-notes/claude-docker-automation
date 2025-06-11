#!/bin/bash

# Fixed Claude launcher that properly starts Claude Code in Docker
set -e

PROJECT_PATH="${1:-$(pwd)}"
TASK_FILE="${2:-CLAUDE_TASKS.md}"
SESSION_ID="${3:-session-$(date +%Y%m%d-%H%M%S)}"

echo "🚀 Starting Claude Code in Docker..."
echo "📁 Project: $PROJECT_PATH"
echo "📋 Task file: $TASK_FILE"
echo "🆔 Session: $SESSION_ID"

# Ensure the task file exists
if [ ! -f "$PROJECT_PATH/$TASK_FILE" ]; then
    echo "❌ Error: Task file not found: $PROJECT_PATH/$TASK_FILE"
    exit 1
fi

# Use 'claude' command directly if available, otherwise use docker
if command -v claude &> /dev/null; then
    echo "✅ Using native Claude Code command..."
    cd "$PROJECT_PATH"
    
    # Create initial instruction file for Claude
    # Clean up session ID to ensure it's a valid filename
    CLEAN_SESSION_ID=$(echo "$SESSION_ID" | tr -d '\n' | sed 's/[^a-zA-Z0-9-]/_/g')
    INSTRUCTION_FILE="/tmp/claude_instructions_${CLEAN_SESSION_ID}.txt"
    
    cat > "$INSTRUCTION_FILE" << 'EOF'
Please read the CLAUDE_TASKS.md file in this workspace and complete all the tasks defined within it.

Key requirements:
1. Create a feature branch for your work
2. Update PROGRESS.md as you complete tasks
3. Make frequent commits with descriptive messages
4. Create SUMMARY.md when all tasks are complete
5. Document any issues in ISSUES.md

Start by reading CLAUDE_TASKS.md to understand the full scope of work.
EOF
    
    # Start Claude Code with the project
    claude "$PROJECT_PATH" --message "$(cat "$INSTRUCTION_FILE")"
    
    # Clean up
    rm -f "$INSTRUCTION_FILE"
else
    echo "🐳 Using Docker to run Claude Code..."
    
    # Create a container name
    CONTAINER_NAME="claude-$SESSION_ID"
    
    # Run Claude Code in Docker interactively
    docker run -it --rm \
        --name "$CONTAINER_NAME" \
        -v "$PROJECT_PATH:/workspace" \
        -w /workspace \
        ghcr.io/anthropics/claude-code:latest
fi

echo "✅ Claude session completed"