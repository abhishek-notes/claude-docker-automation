#!/bin/bash

# Clean Setup Script for Claude Docker Automation

echo "🧹 Cleaning up existing aliases..."

# Remove any existing claude aliases/functions
unalias claude-work 2>/dev/null || true
unalias claude-start 2>/dev/null || true
unset -f claude-work 2>/dev/null || true
unset -f claude-start 2>/dev/null || true

echo "✅ Cleanup complete"
echo ""
echo "🔧 Loading environment..."

# Load environment
source .env

echo "🔧 Loading aliases..."

# Load aliases
source claude-aliases.sh

echo "✅ Setup complete!"
echo ""
echo "📋 Available commands:"
echo "  claude-start [path] [task-file]  - Start autonomous session"
echo "  claude-quick [path]              - Quick session"
echo "  claude-list                      - List active sessions"
echo "  claude-attach                    - Attach to session"
echo "  claude-stop                      - Stop all sessions"
echo "  claude-status                    - Show system status"
echo "  claude-new-project <name>        - Create new project"
echo ""
echo "🚀 Ready to launch!"
