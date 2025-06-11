#!/bin/bash

# Manual Backup Commands for Claude Projects
# Fast, selective backups that you can run when needed

set -e

# Configuration
BACKUP_BASE="/Users/abhishek/Work/claude-project-backups"
EXCLUDE_PATTERNS=(
    "node_modules"
    ".git"
    "*.log"
    ".DS_Store"
    "tmp"
    "temp"
    "vendor"
    "venv"
    "__pycache__"
    ".env"
    "*.tmp"
    "dist"
    "build"
)

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN:${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"; }

# Create backup directory
setup_backup_dir() {
    mkdir -p "$BACKUP_BASE"
}

# Build exclude parameters for rsync
build_exclude_params() {
    local excludes=()
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        excludes+=(--exclude="$pattern")
    done
    echo "${excludes[@]}"
}

# Quick backup of a specific project
backup_project() {
    local project_path="$1"
    local backup_name="${2:-$(basename "$project_path")}"
    
    if [ ! -d "$project_path" ]; then
        error "Project directory does not exist: $project_path"
        return 1
    fi
    
    setup_backup_dir
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="$BACKUP_BASE/${backup_name}-${timestamp}"
    
    log "📦 Backing up: $project_path"
    log "📁 To: $backup_dir"
    
    # Use rsync with excludes for fast backup
    local exclude_params=($(build_exclude_params))
    
    rsync -av \
        "${exclude_params[@]}" \
        --progress \
        "$project_path/" \
        "$backup_dir/"
    
    # Create backup metadata
    cat > "$backup_dir/.backup-info.json" << EOF
{
    "source_path": "$project_path",
    "backup_name": "$backup_name",
    "timestamp": "$timestamp",
    "backup_type": "manual",
    "excludes": $(printf '%s\n' "${EXCLUDE_PATTERNS[@]}" | jq -R . | jq -s .)
}
EOF
    
    log "✅ Backup completed: $backup_dir"
    
    # Show backup size
    local backup_size=$(du -sh "$backup_dir" | cut -f1)
    log "📊 Backup size: $backup_size"
    
    echo "$backup_dir"
}

# Backup important Claude projects
backup_claude_projects() {
    log "🔄 Backing up important Claude projects..."
    
    local projects=(
        "/Users/abhishek/Work/claude-docker-automation:automation"
        "/Users/abhishek/Work/palladio-software-25:palladio"
        "/Users/abhishek/Work/claude-automation:claude-automation"
        "/Users/abhishek/Work/aralco-salesforce-migration:aralco"
    )
    
    for project_info in "${projects[@]}"; do
        IFS=':' read -r project_path project_name <<< "$project_info"
        
        if [ -d "$project_path" ]; then
            log "📦 Backing up $project_name..."
            backup_project "$project_path" "$project_name"
        else
            warn "Project not found: $project_path"
        fi
    done
    
    log "🎉 All project backups completed!"
}

# Backup with git info
backup_project_with_git() {
    local project_path="$1"
    local backup_name="${2:-$(basename "$project_path")}"
    
    if [ ! -d "$project_path" ]; then
        error "Project directory does not exist: $project_path"
        return 1
    fi
    
    log "📦 Backing up with git info: $project_path"
    
    # First do regular backup
    local backup_dir=$(backup_project "$project_path" "$backup_name")
    
    # Add git information if it's a git repo
    if [ -d "$project_path/.git" ]; then
        log "📝 Adding git information..."
        
        cd "$project_path"
        
        # Git status
        git status --porcelain > "$backup_dir/.git-status.txt" 2>/dev/null || true
        
        # Current branch and commit
        git branch --show-current > "$backup_dir/.git-branch.txt" 2>/dev/null || true
        git rev-parse HEAD > "$backup_dir/.git-commit.txt" 2>/dev/null || true
        
        # Recent commits
        git log --oneline -10 > "$backup_dir/.git-log.txt" 2>/dev/null || true
        
        # Diff of uncommitted changes
        git diff > "$backup_dir/.git-diff.txt" 2>/dev/null || true
        
        log "✅ Git information added to backup"
    fi
    
    echo "$backup_dir"
}

# Quick backup before risky operations
quick_backup() {
    local project_path="${1:-$(pwd)}"
    
    log "⚡ Quick backup of current directory..."
    backup_project "$project_path" "quick-$(basename "$project_path")"
}

# List recent backups
list_backups() {
    if [ ! -d "$BACKUP_BASE" ]; then
        warn "No backups found. Backup directory doesn't exist."
        return 0
    fi
    
    echo -e "${BLUE}=== Recent Backups ===${NC}"
    echo ""
    
    # List backups sorted by date
    ls -lt "$BACKUP_BASE" | head -20 | while read line; do
        if [[ $line =~ ^d ]]; then
            local backup_name=$(echo "$line" | awk '{print $NF}')
            local backup_path="$BACKUP_BASE/$backup_name"
            local size=$(du -sh "$backup_path" 2>/dev/null | cut -f1)
            
            printf "%-40s %s\n" "$backup_name" "$size"
        fi
    done
}

# Restore from backup
restore_backup() {
    local backup_name="$1"
    local restore_to="${2:-$(pwd)}"
    
    if [ -z "$backup_name" ]; then
        error "Please specify backup name"
        echo "Available backups:"
        list_backups
        return 1
    fi
    
    local backup_path="$BACKUP_BASE/$backup_name"
    
    if [ ! -d "$backup_path" ]; then
        error "Backup not found: $backup_path"
        return 1
    fi
    
    log "🔄 Restoring backup: $backup_name"
    log "📁 To: $restore_to"
    
    read -p "Are you sure? This will overwrite files in $restore_to (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "Restore cancelled"
        return 0
    fi
    
    mkdir -p "$restore_to"
    
    rsync -av \
        --progress \
        "$backup_path/" \
        "$restore_to/"
    
    log "✅ Restore completed"
}

# Clean up old backups
cleanup_backups() {
    local keep_count="${1:-10}"
    
    if [ ! -d "$BACKUP_BASE" ]; then
        warn "No backup directory found"
        return 0
    fi
    
    log "🧹 Cleaning up old backups (keeping last $keep_count)..."
    
    cd "$BACKUP_BASE"
    local backup_count=$(find . -maxdepth 1 -type d -name "*-*" | wc -l)
    
    if [ "$backup_count" -gt "$keep_count" ]; then
        local to_remove=$((backup_count - keep_count))
        
        find . -maxdepth 1 -type d -name "*-*" -print0 | \
            xargs -0 ls -dt | \
            tail -n "$to_remove" | \
            while read backup_dir; do
                log "🗑️ Removing old backup: $(basename "$backup_dir")"
                rm -rf "$backup_dir"
            done
            
        log "✅ Removed $to_remove old backups"
    else
        log "ℹ️ No cleanup needed (only $backup_count backups)"
    fi
}

# Main command dispatcher
case "${1:-help}" in
    "project")
        backup_project "${2:-$(pwd)}" "$3"
        ;;
        
    "git")
        backup_project_with_git "${2:-$(pwd)}" "$3"
        ;;
        
    "quick")
        quick_backup "$2"
        ;;
        
    "all")
        backup_claude_projects
        ;;
        
    "list")
        list_backups
        ;;
        
    "restore")
        restore_backup "$2" "$3"
        ;;
        
    "cleanup")
        cleanup_backups "$2"
        ;;
        
    "help"|*)
        cat << 'EOF'
Manual Backup Commands for Claude Projects

USAGE:
    ./manual-backup.sh <command> [args...]

COMMANDS:
    project <path> [name]    - Backup specific project directory
    git <path> [name]        - Backup project with git information
    quick [path]             - Quick backup of current/specified directory
    all                      - Backup all important Claude projects
    list                     - List recent backups
    restore <backup> [to]    - Restore from backup
    cleanup [keep-count]     - Clean up old backups (default: keep 10)
    help                     - Show this help

EXAMPLES:
    ./manual-backup.sh project /Users/abhishek/Work/palladio-software-25
    ./manual-backup.sh git /Users/abhishek/Work/claude-docker-automation
    ./manual-backup.sh quick
    ./manual-backup.sh all
    ./manual-backup.sh list
    ./manual-backup.sh restore palladio-20250609-163000
    ./manual-backup.sh cleanup 5

FEATURES:
    • Fast rsync-based backups with smart excludes
    • Git information preservation
    • Backup metadata and timestamps
    • Easy restore functionality
    • Automatic cleanup of old backups
    • Progress indicators

BACKUP LOCATION:
    /Users/abhishek/Work/claude-project-backups

EXCLUDES:
    node_modules, .git, *.log, .DS_Store, tmp, temp, vendor, 
    venv, __pycache__, .env, *.tmp, dist, build
EOF
        ;;
esac