#!/bin/bash

# Claude Docker Automation Safety System
# Provides backup, versioning, and safety features integrated from claude-automation

set -e

# Configuration
AUTOMATION_DIR="/Users/abhishek/Work/claude-docker-automation"
BACKUP_DIR="$AUTOMATION_DIR/backups"
LOGS_DIR="$AUTOMATION_DIR/logs"
SESSION_DIR="$AUTOMATION_DIR/sessions"

# Load environment
source "$AUTOMATION_DIR/.env" 2>/dev/null || true

# Ensure directories exist
mkdir -p "$BACKUP_DIR" "$LOGS_DIR" "$SESSION_DIR"

# Logging function
log_event() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOGS_DIR/safety-system.log"
}

# Create backup with versioning
create_backup() {
    local project_path="$1"
    local backup_type="${2:-manual}"
    
    if [[ ! -d "$project_path" ]]; then
        log_event "ERROR" "Project path does not exist: $project_path"
        return 1
    fi
    
    local project_name=$(basename "$project_path")
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_name="${project_name}-${backup_type}-${timestamp}"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log_event "INFO" "Creating backup: $backup_name"
    
    # Create backup directory
    mkdir -p "$backup_path"
    
    # Copy project files (excluding common ignore patterns)
    rsync -av \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='.DS_Store' \
        --exclude='*.log' \
        --exclude='.env' \
        --exclude='tmp' \
        --exclude='temp' \
        "$project_path/" "$backup_path/"
    
    # Create metadata
    cat > "$backup_path/.backup-metadata.json" << EOF
{
    "project_path": "$project_path",
    "backup_type": "$backup_type",
    "timestamp": "$timestamp",
    "created_by": "claude-docker-automation",
    "git_hash": "$(cd "$project_path" && git rev-parse HEAD 2>/dev/null || echo 'no-git')",
    "git_branch": "$(cd "$project_path" && git branch --show-current 2>/dev/null || echo 'no-git')"
}
EOF
    
    log_event "INFO" "Backup created successfully: $backup_path"
    echo "$backup_path"
}

# Pre-task safety check
pre_task_check() {
    local project_path="$1"
    local task_description="$2"
    
    log_event "INFO" "Running pre-task safety check for: $project_path"
    
    # Check if project has uncommitted changes
    if [[ -d "$project_path/.git" ]]; then
        cd "$project_path"
        if ! git diff-index --quiet HEAD --; then
            log_event "WARN" "Project has uncommitted changes, creating backup"
            create_backup "$project_path" "pre-task"
        fi
    fi
    
    # Check project size (warn if > 100MB)
    local project_size=$(du -sm "$project_path" 2>/dev/null | cut -f1 || echo "0")
    if [[ $project_size -gt 100 ]]; then
        log_event "WARN" "Large project detected (${project_size}MB), consider selective backup"
    fi
    
    # Create session file
    local session_id="session-$(date +%Y%m%d-%H%M%S)"
    local session_file="$SESSION_DIR/$session_id.json"
    
    cat > "$session_file" << EOF
{
    "session_id": "$session_id",
    "project_path": "$project_path",
    "task_description": "$task_description",
    "start_time": "$(date -Iseconds)",
    "safety_checks": {
        "backup_created": true,
        "git_status_checked": true,
        "project_size_mb": $project_size
    }
}
EOF
    
    echo "$session_id"
}

# Post-task cleanup and validation
post_task_check() {
    local session_id="$1"
    local project_path="$2"
    local exit_code="${3:-0}"
    
    log_event "INFO" "Running post-task check for session: $session_id"
    
    # Update session file
    local session_file="$SESSION_DIR/$session_id.json"
    if [[ -f "$session_file" ]]; then
        # Create temporary file with updated session
        local temp_file=$(mktemp)
        jq ". + {\"end_time\": \"$(date -Iseconds)\", \"exit_code\": $exit_code, \"completed\": true}" "$session_file" > "$temp_file"
        mv "$temp_file" "$session_file"
    fi
    
    # Check for new files/changes
    if [[ -d "$project_path/.git" ]]; then
        cd "$project_path"
        local changes=$(git status --porcelain | wc -l)
        if [[ $changes -gt 0 ]]; then
            log_event "INFO" "Task created $changes file changes"
            create_backup "$project_path" "post-task"
        fi
    fi
    
    log_event "INFO" "Post-task check completed for session: $session_id"
}

# Cleanup old backups (keep last 10)
cleanup_backups() {
    log_event "INFO" "Cleaning up old backups"
    
    cd "$BACKUP_DIR"
    local backup_count=$(find . -maxdepth 1 -type d -name "*-*-*" | wc -l)
    
    if [[ $backup_count -gt 10 ]]; then
        local to_remove=$((backup_count - 10))
        find . -maxdepth 1 -type d -name "*-*-*" -print0 | \
            xargs -0 ls -dt | \
            tail -n $to_remove | \
            xargs rm -rf
        log_event "INFO" "Removed $to_remove old backups"
    fi
}

# Monitor system resources
check_resources() {
    local cpu_usage=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    local memory_pressure=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//' || echo "unknown")
    
    log_event "INFO" "System resources - CPU: ${cpu_usage}%, Memory free: ${memory_pressure}%"
    
    # Warn if resources are low
    if [[ "$cpu_usage" =~ ^[0-9]+$ ]] && [[ $cpu_usage -gt 80 ]]; then
        log_event "WARN" "High CPU usage detected: ${cpu_usage}%"
    fi
}

# Main function
main() {
    case "$1" in
        backup)
            create_backup "$2" "${3:-manual}"
            ;;
        pre-check)
            pre_task_check "$2" "$3"
            ;;
        post-check)
            post_task_check "$2" "$3" "$4"
            ;;
        cleanup)
            cleanup_backups
            ;;
        monitor)
            check_resources
            ;;
        *)
            echo "Usage: $0 {backup|pre-check|post-check|cleanup|monitor} [args...]"
            echo "  backup <project-path> [type]"
            echo "  pre-check <project-path> <task-description>"
            echo "  post-check <session-id> <project-path> [exit-code]"
            echo "  cleanup"
            echo "  monitor"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi