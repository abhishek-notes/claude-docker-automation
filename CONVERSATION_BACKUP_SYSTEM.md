# Claude Docker Conversation Backup System

## Overview

The conversation backup system automatically saves all Claude Code conversations from Docker containers to your Mac filesystem, ensuring you never lose important conversation history.

## Features

- ✅ **Automatic Backup**: Conversations are backed up when starting/stopping containers
- ✅ **Manual Backup**: Run backups anytime with simple commands
- ✅ **Search & Recovery**: Find and restore specific conversations
- ✅ **Metadata Tracking**: Detailed information about each conversation
- ✅ **Auto-cleanup**: Old backups are automatically archived
- ✅ **Multiple Formats**: Raw JSONL files + human-readable summaries

## Quick Start

### Backup All Conversations
```bash
./claude-backup-alias.sh backup
```

### Check Backup Status
```bash
./claude-backup-alias.sh status
```

### Search for Conversations
```bash
./claude-backup-alias.sh find "dashboard"
./claude-backup-alias.sh find "bank-nifty"
```

### List Recent Conversations
```bash
./claude-backup-alias.sh list
```

## Your Recovered Bank-Nifty Dashboard Work

Your specific conversation about bank-nifty dashboard comparison has been recovered:

**Session ID**: `54f1b9b6-a2a2-4a91-9836-f98330b15c20`

**Location**: 
- Raw conversation: `~/.claude-docker-conversations/conversations/54f1b9b6-a2a2-4a91-9836-f98330b15c20.jsonl`
- Summary: `~/.claude-docker-conversations/exports/54f1b9b6-a2a2-4a91-9836-f98330b15c20_summary.md`

**Details**: 
- 664 messages
- 5MB conversation data
- Contains your dashboard work comparing raw ticks with parquet data

## How It Works

### Automatic Integration

The backup system is integrated into `claude-docker-persistent.sh`:

1. **On Start**: Backs up existing conversations before starting new container
2. **On Stop**: Automatically backs up conversations when stopping containers

### Manual Commands

#### Using the Docker Script
```bash
./claude-docker-persistent.sh backup status    # Check status
./claude-docker-persistent.sh backup backup    # Manual backup
./claude-docker-persistent.sh stop             # Stop with backup
```

#### Using the Alias Script
```bash
./claude-backup-alias.sh backup               # Backup all
./claude-backup-alias.sh status               # Show status
./claude-backup-alias.sh list                 # List conversations
./claude-backup-alias.sh find "keyword"       # Search conversations
./claude-backup-alias.sh restore session-id   # Restore conversation
```

## File Structure

```
~/.claude-docker-conversations/
├── conversations/          # Raw JSONL conversation files
│   ├── session-id-1.jsonl
│   └── session-id-2.jsonl
├── metadata/              # Conversation metadata
│   ├── session-id-1_metadata.json
│   └── session-id-2_metadata.json
├── exports/               # Human-readable summaries
│   ├── session-id-1_summary.md
│   └── session-id-2_summary.md
└── README.md             # Documentation
```

## Restoring Conversations

To restore a conversation back to Claude:

```bash
./claude-backup-alias.sh restore 54f1b9b6-a2a2-4a91-9836-f98330b15c20
```

This copies the conversation back to the Docker volume where Claude can access it.

## Technical Details

### Backup Process

1. **Discovery**: Scans Docker volume `claude-code-config` for JSONL files
2. **Copy**: Creates local copies of all conversation files
3. **Metadata**: Extracts session info, timestamps, and file details
4. **Export**: Creates readable summaries for easy browsing
5. **Cleanup**: Removes backups older than 30 days

### Security

- Conversations are stored locally on your Mac
- No data is sent to external services
- Sensitive information is filtered during backup
- Files are accessible only to your user account

### Storage

- Backup location: `~/.claude-docker-conversations/`
- Typical size: 1-10MB per conversation
- Auto-cleanup after 30 days
- Current backup: 29 conversations, 104MB total

## Troubleshooting

### Common Issues

1. **Docker not running**: Start Docker Desktop
2. **Permission errors**: Ensure script is executable (`chmod +x`)
3. **Volume not found**: Run a Docker container first to create volumes

### Commands

```bash
# Check if Docker is running
docker ps

# Check if backup script is executable
ls -la conversation-backup.sh

# View backup logs
./conversation-backup.sh backup

# Manual volume inspection
docker volume ls | grep claude
```

## Next Steps

1. **Automatic**: The system now runs automatically with your Docker containers
2. **Search**: Use `find` command to locate specific conversations
3. **Restore**: Use `restore` command to bring conversations back to Claude
4. **Monitor**: Check `status` regularly to ensure backups are working

Your bank-nifty dashboard conversation is now safely backed up and searchable!