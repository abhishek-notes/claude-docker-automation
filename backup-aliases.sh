#!/bin/bash

# Backup Aliases for Easy Access
# Source this file or add to your .zshrc

AUTOMATION_DIR="/Users/abhishek/Work/claude-docker-automation"

# Quick backup aliases
alias backup-quick="$AUTOMATION_DIR/manual-backup.sh quick"
alias backup-project="$AUTOMATION_DIR/manual-backup.sh project"
alias backup-git="$AUTOMATION_DIR/manual-backup.sh git"
alias backup-all="$AUTOMATION_DIR/manual-backup.sh all"
alias backup-list="$AUTOMATION_DIR/manual-backup.sh list"
alias backup-restore="$AUTOMATION_DIR/manual-backup.sh restore"
alias backup-cleanup="$AUTOMATION_DIR/manual-backup.sh cleanup"

# Specific project backups
alias backup-palladio="$AUTOMATION_DIR/manual-backup.sh project /Users/abhishek/Work/palladio-software-25 palladio"
alias backup-automation="$AUTOMATION_DIR/manual-backup.sh project /Users/abhishek/Work/claude-docker-automation automation"
alias backup-aralco="$AUTOMATION_DIR/manual-backup.sh project /Users/abhishek/Work/aralco-salesforce-migration aralco"

# Git-aware backups
alias backup-current-git="$AUTOMATION_DIR/manual-backup.sh git ."
alias backup-palladio-git="$AUTOMATION_DIR/manual-backup.sh git /Users/abhishek/Work/palladio-software-25 palladio"

echo "Backup aliases loaded! Try:"
echo "  backup-quick        - Quick backup of current directory"
echo "  backup-all          - Backup all important projects"
echo "  backup-list         - List recent backups"
echo "  backup-palladio     - Backup Palladio project"
echo "  backup-automation   - Backup automation scripts"