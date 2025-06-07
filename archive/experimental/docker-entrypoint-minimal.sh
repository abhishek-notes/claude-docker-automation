#!/bin/bash

# Minimal Docker entrypoint for Claude Code
set -e

# Setup git
git config --global init.defaultBranch main
git config --global user.name "${GIT_USER_NAME:-Claude Bot}"
git config --global user.email "${GIT_USER_EMAIL:-claude@automation.local}"
git config --global --add safe.directory '*'

# Handle Claude authentication
if [ -f "/home/claude/.claude.json.readonly" ]; then
    cp /home/claude/.claude.json.readonly /home/claude/.claude.json
    chmod 600 /home/claude/.claude.json
fi

# Change to workspace
cd /workspace 2>/dev/null || cd /home/claude/workspace

# Execute command
exec "$@"