#!/bin/bash

# Quick Setup Script for Claude Automation
# Run this once to set everything up!

set -euo pipefail

AUTOMATION_DIR="/Users/abhishek/Work/claude-automation"

echo "🚀 Claude Automation Quick Setup"
echo "================================"

# Make all scripts executable
echo "Setting up permissions..."
chmod +x "$AUTOMATION_DIR"/*.sh 2>/dev/null || true
chmod +x "$AUTOMATION_DIR"/*.js 2>/dev/null || true
chmod +x "$AUTOMATION_DIR/collaboration"/*.sh 2>/dev/null || true
chmod +x "$AUTOMATION_DIR/collaboration"/*.js 2>/dev/null || true

# Create .env template
echo "Creating environment template..."
cat > "$AUTOMATION_DIR/.env.template" << 'EOF'
# API Keys (Optional - for API-based collaboration)
ANTHROPIC_API_KEY=your_api_key_here
OPENAI_API_KEY=your_api_key_here
GOOGLE_AI_API_KEY=your_api_key_here
GITHUB_TOKEN=your_github_token_here

# Paths
PROJECT_PATH=/Users/abhishek/Work/your-project
BACKUP_PATH=/Users/abhishek/Work/claude-automation/backups
EOF

# Create aliases for easier access
echo "Creating aliases..."
cat > "$AUTOMATION_DIR/setup-aliases.sh" << 'EOF'
# Add these to your ~/.zshrc or ~/.bashrc

# Claude Automation Aliases
alias claude-work="/Users/abhishek/Work/claude-automation/ultimate-launch.sh"
alias claude-dash="open /Users/abhishek/Work/claude-automation/dashboard/index.html"
alias claude-logs="cd /Users/abhishek/Work/claude-automation/logs && ls -la"
alias claude-backup="cd /Users/abhishek/Work/claude-automation/backups && ls -la"
alias claude-collab="/Users/abhishek/Work/claude-automation/collaboration/orchestrate.sh"
alias claude-status="ps aux | grep -E '(claude|node.*mcp)' | grep -v grep"

# Quick task creation
claude-task() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local filename="/Users/abhishek/Work/claude-automation/instructions/task-$timestamp.md"
    cp /Users/abhishek/Work/claude-automation/instructions/MASTER_TEMPLATE.md "$filename"
    echo "Created new task file: $filename"
    ${EDITOR:-nano} "$filename"
}

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
EOF

# Update MCP config
echo "Updating MCP configuration..."
MCP_CONFIG_PATH="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

# Create backup of existing config
if [ -f "$MCP_CONFIG_PATH" ]; then
    cp "$MCP_CONFIG_PATH" "$MCP_CONFIG_PATH.backup-$(date +%Y%m%d-%H%M%S)"
fi

# Write updated config
cat > "$MCP_CONFIG_PATH" << 'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/abhishek/Desktop",
        "/Users/abhishek/Downloads",
        "/Users/abhishek/DevKinsta",
        "/Users/abhishek/Work"
      ]
    },
    "applescript_execute": {
      "command": "npx",
      "args": ["@peakmojo/applescript-mcp"]
    },
    "browsermcp": {
      "command": "npx",
      "args": ["@browsermcp/mcp@latest"]
    },
    "smart-operations": {
      "command": "node",
      "args": ["/Users/abhishek/Work/claude-automation/mcp-smart-ops.js"]
    },
    "github": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
EOF

# Install required npm packages globally
echo "Installing required packages..."
npm install -g @anthropic-ai/claude-code @modelcontextprotocol/sdk || true

# Create example templates
echo "Creating task templates..."
mkdir -p "$AUTOMATION_DIR/templates/tasks"

# API Endpoint Template
cat > "$AUTOMATION_DIR/templates/tasks/api-endpoint.md" << 'EOF'
# API Endpoint Implementation Task

## Project Context
- Repository: [YOUR_REPO]
- API Framework: Express/FastAPI/etc
- Database: PostgreSQL/MongoDB/etc

## Today's Tasks

1. Implement REST API Endpoint
   - Requirements:
     - Endpoint: POST /api/v1/[resource]
     - Authentication: JWT required
     - Validation: Input schema validation
     - Error handling: Proper HTTP status codes
   - Expected outcome:
     - Working endpoint with tests
     - OpenAPI documentation
     - Error handling for edge cases
   - Time estimate: 2 hours

2. Add Database Integration
   - Requirements:
     - Create model/schema
     - Add migrations
     - Implement CRUD operations
     - Add transaction support
   - Expected outcome:
     - Database operations working
     - Proper indexing
     - Migration files created
   - Time estimate: 1.5 hours

## Rules & Constraints
- Use existing patterns from codebase
- Follow RESTful conventions
- Add rate limiting
- Include request/response logging
- Write integration tests
EOF

# Bug Fix Template
cat > "$AUTOMATION_DIR/templates/tasks/bug-fix.md" << 'EOF'
# Bug Fix Task

## Project Context
- Repository: [YOUR_REPO]
- Bug Report: #[ISSUE_NUMBER]
- Severity: High/Medium/Low

## Bug Description
[Describe the bug here]

## Today's Tasks

1. Reproduce and Diagnose Bug
   - Requirements:
     - Create minimal reproduction case
     - Add debugging logs
     - Identify root cause
     - Document findings
   - Expected outcome:
     - Clear understanding of issue
     - Reproduction steps documented
   - Time estimate: 1 hour

2. Implement Fix
   - Requirements:
     - Fix the root cause
     - Ensure no side effects
     - Add regression tests
     - Update related documentation
   - Expected outcome:
     - Bug resolved
     - Tests preventing regression
     - No new issues introduced
   - Time estimate: 2 hours

## Testing Requirements
- Unit tests for the fix
- Integration tests if needed
- Manual testing steps
- Performance impact check
EOF

# Feature Template
cat > "$AUTOMATION_DIR/templates/tasks/new-feature.md" << 'EOF'
# New Feature Implementation

## Project Context
- Repository: [YOUR_REPO]
- Feature: [FEATURE_NAME]
- Related Issue: #[ISSUE_NUMBER]

## Feature Requirements
[Detailed feature requirements]

## Today's Tasks

1. Design and Architecture
   - Requirements:
     - Review existing patterns
     - Design data models
     - Plan API interfaces
     - Consider edge cases
   - Expected outcome:
     - Technical design document
     - API specification
     - Database schema
   - Time estimate: 1 hour

2. Core Implementation
   - Requirements:
     - Implement business logic
     - Add data models
     - Create API endpoints
     - Add validation
   - Expected outcome:
     - Feature working end-to-end
     - All tests passing
     - Code documented
   - Time estimate: 3 hours

3. Testing Suite
   - Requirements:
     - Unit tests (>80% coverage)
     - Integration tests
     - E2E test scenarios
     - Performance benchmarks
   - Expected outcome:
     - Comprehensive test coverage
     - All edge cases tested
     - Performance validated
   - Time estimate: 2 hours

## Documentation Requirements
- API documentation
- User guide
- Migration guide if needed
- Architecture decisions record
EOF

# Create package.json for MCP server
cat > "$AUTOMATION_DIR/package.json" << 'EOF'
{
  "name": "claude-automation",
  "version": "1.0.0",
  "description": "Claude Automation System with MCP Servers",
  "type": "module",
  "scripts": {
    "start": "./ultimate-launch.sh",
    "collab": "./setup-collaboration.sh",
    "dashboard": "open dashboard/index.html",
    "mcp-server": "node mcp-smart-ops.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "latest",
    "@anthropic-ai/claude-code": "latest"
  }
}
EOF

# Final setup message
echo ""
echo "✅ Setup Complete!"
echo ""
echo "📁 Created in: $AUTOMATION_DIR"
echo ""
echo "🚀 Quick Start:"
echo "   1. Add aliases to your shell:"
echo "      echo 'source $AUTOMATION_DIR/setup-aliases.sh' >> ~/.zshrc"
echo "      source ~/.zshrc"
echo ""
echo "   2. Create your first task:"
echo "      claude-task"
echo ""
echo "   3. Launch automation:"
echo "      claude-work 4"
echo ""
echo "   4. View dashboard:"
echo "      claude-dash"
echo ""
echo "🤝 For collaboration without APIs:"
echo "   $AUTOMATION_DIR/setup-collaboration.sh"
echo ""
echo "📚 Templates available in:"
echo "   $AUTOMATION_DIR/templates/tasks/"
echo ""
echo "Happy automating! 🎉"
