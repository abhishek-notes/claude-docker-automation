# Add these to your ~/.zshrc or ~/.bashrc

# Claude Automation Aliases
alias claude-work="/Users/abhishek/Work/claude-automation/claude-launcher.sh"
alias claude-dash="open /Users/abhishek/Work/claude-automation/dashboard/index.html"
alias claude-logs="cd /Users/abhishek/Work/claude-automation/logs && ls -la"
alias claude-backup="cd /Users/abhishek/Work/claude-automation/backups && ls -la"
alias claude-collab="/Users/abhishek/Work/claude-automation/collaboration/orchestrate.sh"
alias claude-status="ps aux | grep -E '(claude|node.*mcp)' | grep -v grep"

# Quick task creation

# Session management
claude-session() {
    case "$1" in
        start)
            /Users/abhishek/Work/claude-automation/ultimate-launch.sh "${2:-4}" "${3:-}"
            ;;
        stop)
            pkill -f "claude" || true
            echo "Claude sessions stopped"
            ;;
        status)
            claude-status
            ;;
        *)
            echo "Usage: claude-session {start|stop|status} [hours] [task-file]"
            ;;
    esac
}
