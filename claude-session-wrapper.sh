#!/bin/bash

# Claude Session Wrapper with Conversation Persistence
# Wraps any Claude session to ensure conversations are preserved

set -e

AUTOMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSISTENCE_SCRIPT="$AUTOMATION_DIR/lightweight-persistence.sh"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }

# Pre-session setup
pre_session_setup() {
    log "🔧 Setting up conversation persistence..."
    
    # Ensure persistence system is available
    if [ ! -f "$PERSISTENCE_SCRIPT" ]; then
        echo "❌ Conversation persistence system not found!"
        exit 1
    fi
    
    # Quick conversation backup (non-blocking)
    "$PERSISTENCE_SCRIPT" quick-backup
    
    # Start lightweight monitoring
    log "🔍 Starting lightweight conversation monitor..."
    "$PERSISTENCE_SCRIPT" start-monitor &
    MONITOR_PID=$!
    
    # Save monitor PID for cleanup
    echo $MONITOR_PID > /tmp/claude-monitor.pid
}

# Post-session cleanup
post_session_cleanup() {
    log "💾 Final conversation backup..."
    
    # Final quick backup
    "$PERSISTENCE_SCRIPT" quick-backup
    
    # Cleanup old files
    "$PERSISTENCE_SCRIPT" cleanup
    
    # Stop monitor
    if [ -f /tmp/claude-monitor.pid ]; then
        local monitor_pid=$(cat /tmp/claude-monitor.pid)
        kill $monitor_pid 2>/dev/null || true
        rm -f /tmp/claude-monitor.pid
    fi
    
    log "✅ Session cleanup completed"
}

# Trap to ensure cleanup on exit
trap post_session_cleanup EXIT INT TERM

# Main wrapper function
wrap_claude_session() {
    local command="$1"
    shift
    
    log "🚀 Starting Claude session with persistence..."
    
    # Pre-session setup
    pre_session_setup
    
    log "▶️ Executing: $command $*"
    
    # Execute the actual Claude command preserving environment
    exec "$command" "$@"
    
    # Post-session cleanup happens automatically via trap
}

# Usage
if [ $# -eq 0 ]; then
    cat << 'EOF'
Claude Session Wrapper with Conversation Persistence

USAGE:
    ./claude-session-wrapper.sh <claude-command> [args...]

EXAMPLES:
    ./claude-session-wrapper.sh ./claude-direct-task.sh /path/to/project
    ./claude-session-wrapper.sh ./claude-terminal-launcher.sh /path/to/project CLAUDE_TASKS.md

FEATURES:
    • Automatic conversation backup before/after sessions
    • Real-time conversation monitoring during sessions
    • Clean conversation export after each session
    • Automatic recovery if sessions crash
    • Persistent storage across Docker restarts

Your conversations will be automatically saved to:
    /Users/abhishek/Work/claude-conversations-backup
    /Users/abhishek/Work/claude-conversations-exports
EOF
    exit 0
fi

# Execute the wrapped session
wrap_claude_session "$@"