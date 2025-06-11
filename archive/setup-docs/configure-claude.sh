#!/bin/bash

# Pre-configure Claude Code to skip first-time setup
# This eliminates login prompts and theme selection

# Create Claude Code configuration directory
mkdir -p /home/claude/.claude

# Create a pre-configured settings file to skip setup
cat > /home/claude/.claude/settings.json << 'EOF'
{
  "theme": "dark",
  "setupComplete": true,
  "firstRun": false,
  "hasShownWelcome": true,
  "telemetryEnabled": false,
  "autoUpdate": false
}
EOF

# Create Claude Code config file
cat > /home/claude/.claude/config.json << 'EOF'
{
  "setupComplete": true,
  "firstTimeSetup": false,
  "theme": "dark",
  "analytics": false,
  "autoUpdate": false
}
EOF

# Set proper permissions
chmod 600 /home/claude/.claude/settings.json
chmod 600 /home/claude/.claude/config.json

echo "✅ Claude Code pre-configured to skip setup prompts"
