# Add these to your ~/.zshrc or ~/.bashrc

# Claude Docker Automation Aliases
export CLAUDE_DOCKER_PATH="/Users/abhishek/Work/claude-docker-automation"
alias claude-work="$CLAUDE_DOCKER_PATH/claude-terminal-launcher.sh"
alias claude-dash="open $CLAUDE_DOCKER_PATH/web/index.html"
alias claude-logs="cd $CLAUDE_DOCKER_PATH/logs && ls -la || echo 'No logs directory'"
alias claude-backup="cd $CLAUDE_DOCKER_PATH/backups && ls -la || echo 'No backups directory'"
alias claude-status="ps aux | grep -E '(claude|node.*task-api|docker.*claude)' | grep -v grep"
alias claude-direct="$CLAUDE_DOCKER_PATH/claude-direct-task.sh"

# Web interface management
alias claude-web="cd $CLAUDE_DOCKER_PATH && node task-api.js"
alias claude-stop="pkill -f 'task-api.js' || pkill -f 'claude' || true"

# Quick task creation with web interface
claude-task() {
    local project_path="${1:-$PWD}"
    echo "Opening Claude task interface..."
    claude-web &
    sleep 2
    open "http://localhost:3000"
    echo "Web interface running at http://localhost:3000"
    echo "Project path: $project_path"
}

# Session management
claude-session() {
    case "$1" in
        start)
            claude-task "${2:-$PWD}"
            ;;
        web)
            claude-web
            ;;
        stop)
            claude-stop
            echo "Claude sessions stopped"
            ;;
        status)
            claude-status
            ;;
        direct)
            claude-direct "${2:-$PWD}"
            ;;
        *)
            echo "Usage: claude-session {start|web|stop|status|direct} [project-path]"
            echo "  start   - Launch web interface for task creation"
            echo "  web     - Start web API server only"
            echo "  stop    - Stop all Claude processes"
            echo "  status  - Show running Claude processes"
            echo "  direct  - Run direct task launcher (manual mode)"
            ;;
    esac
}
