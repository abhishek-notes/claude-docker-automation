# GitHub Token Setup for Claude Docker Automation

## Overview

This guide explains how to securely store and use GitHub tokens across all your Claude Docker containers.

## Token Storage Location

Your GitHub token is stored in: `/workspace/.env.github`

This file contains:
- `GITHUB_TOKEN` - Your classic GitHub personal access token
- `GH_TOKEN` - Duplicate for compatibility with different tools
- `GITHUB_USERNAME` - Your GitHub username

## Security Features

1. **Gitignored**: The `.env.github` file is in `.gitignore` and won't be committed
2. **Container Access**: All Claude containers can access this token via environment variables
3. **Token Masking**: Scripts display only partial token for security
4. **Validation**: Token is tested before use

## Setup Instructions

### 1. Initial Setup (Already Done)

Your token from the coin-flip-app has been copied to:
```
/workspace/.env.github
```

### 2. Load Token for Current Session

```bash
# Load token into current shell
source /workspace/.env.github

# Or use the setup script
./setup-github-token.sh
```

### 3. Use with Claude Docker Containers

#### Option A: Source Before Running
```bash
# Load token first
source /workspace/.env.github

# Then run Claude container (token will be passed automatically)
./claude-docker-automation/claude-auto.sh
```

#### Option B: Modify Docker Scripts
The claude-auto.sh already includes token passing in lines 100-102:
```bash
if [ -n "${GITHUB_TOKEN:-}" ]; then
    env_vars+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
fi
```

#### Option C: Add to Shell Profile (Permanent)
```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'source /workspace/.env.github' >> ~/.bashrc
```

## Using in Different Claude Containers

### 1. claude-auto.sh (Automated Sessions)
```bash
source /workspace/.env.github
./claude-docker-automation/claude-auto.sh /path/to/project
```

### 2. Docker Compose
```bash
# Set environment variable first
source /workspace/.env.github

# Then use docker-compose
cd claude-docker-automation
docker-compose up
```

### 3. Direct Docker Run
```bash
source /workspace/.env.github

docker run -it \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  -e GH_TOKEN=$GH_TOKEN \
  -v $(pwd):/workspace \
  claude-automation:latest
```

## Token Usage in Containers

Once inside a Claude container, the token is available as:

```bash
# Environment variables
echo $GITHUB_TOKEN
echo $GH_TOKEN

# GitHub CLI authentication (automatic)
gh auth status

# Git operations
git push origin main

# API calls
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user
```

## Best Practices

1. **Never Hardcode**: Always use environment variables
2. **Rotate Regularly**: Update your token periodically
3. **Minimal Permissions**: Use tokens with only necessary scopes
4. **Test Before Use**: Run `./setup-github-token.sh` to validate

## Troubleshooting

### Token Not Working
```bash
# Test token directly
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user

# Re-authenticate GitHub CLI
echo "$GITHUB_TOKEN" | gh auth login --with-token
```

### Container Can't Access Token
```bash
# Check if token is loaded
echo $GITHUB_TOKEN

# If empty, source the file
source /workspace/.env.github
```

### Permission Denied
```bash
# Ensure token has required scopes:
# - repo (full control of private repositories)
# - workflow (if modifying GitHub Actions)
# - read:org (if accessing organization repos)
```

## Security Notes

- Token file permissions: 644 (readable by your user)
- Located outside project directories to avoid accidental commits
- Shared across all containers via environment variables
- Not included in any Git repositories due to .gitignore

## Quick Reference

```bash
# One-time setup (already done)
cp Archives/coin-flip-app/.env /workspace/.env.github

# Before each session
source /workspace/.env.github

# Run Claude with GitHub access
./claude-docker-automation/claude-auto.sh

# Test token
./setup-github-token.sh
```