#!/bin/bash

# Final working ca command using tmux -CC

case "${1:-cc}" in
    "cc"|"all"|"")
        echo "🚀 Opening all Claude sessions with iTerm2 tmux integration..."
        echo ""
        
        # Check if already in tmux
        if [ -n "$TMUX" ]; then
            echo "⚠️  You're already in tmux. Please detach first (Ctrl-b d)"
            exit 1
        fi
        
        # Check if session exists
        if ! tmux has-session -t claude-main 2>/dev/null; then
            echo "❌ No tmux session 'claude-main' found!"
            echo "Run: ~/Work/migrate-all-claude-sessions-enhanced.sh"
            exit 1
        fi
        
        # Detach any existing clients
        tmux detach-client -a -t claude-main 2>/dev/null || true
        
        echo "Opening iTerm2 native tmux tabs..."
        echo ""
        echo "Tips:"
        echo "  • Each tmux window becomes an iTerm2 tab"
        echo "  • To see full history: ~/Work/view-claude-history.sh"
        echo "  • To detach: Close window or Cmd-D"
        echo ""
        
        # Use iTerm2's tmux control mode
        osascript <<'EOF'
tell application "iTerm"
    create window with default profile
    tell current session of current window
        write text "tmux -CC attach -t claude-main"
    end tell
end tell
EOF
        ;;
        
    "single"|"s")
        echo "Attaching to tmux in single window mode..."
        tmux attach -t claude-main
        ;;
        
    "history"|"h")
        ~/Work/view-claude-history.sh
        ;;
        
    "help"|"-h")
        echo "Claude Attach (ca) - Final Version"
        echo ""
        echo "Usage:"
        echo "  ca          - Open all sessions as iTerm2 tabs (default)"
        echo "  ca single   - Single tmux window mode"
        echo "  ca history  - View full session history"
        echo "  ca help     - Show this help"
        echo ""
        echo "Shortcuts:"
        echo "  ca s - Single mode"
        echo "  ca h - History viewer"
        ;;
esac