#!/bin/bash

# Claude Collaboration System - Run Multiple Claude Instances
# Without using expensive APIs - uses desktop apps instead!

set -euo pipefail

AUTOMATION_DIR="/Users/abhishek/Work/claude-automation"
COLLAB_DIR="$AUTOMATION_DIR/collaboration"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create collaboration workspace
setup_collaboration() {
    echo -e "${GREEN}Setting up collaboration workspace...${NC}"
    
    # Create shared directories
    mkdir -p "$COLLAB_DIR/shared-context"
    mkdir -p "$COLLAB_DIR/handoff"
    mkdir -p "$COLLAB_DIR/reviews"
    mkdir -p "$COLLAB_DIR/tasks"
    
    # Create communication files
    touch "$COLLAB_DIR/shared-context/CONTEXT.md"
    touch "$COLLAB_DIR/handoff/CURRENT_WORK.md"
    touch "$COLLAB_DIR/reviews/REVIEW_QUEUE.md"
}

# Create task splitter
create_task_splitter() {
    cat > "$COLLAB_DIR/split-tasks.js" << 'EOF'
#!/usr/bin/env node

// Task Splitter - Divides work between multiple Claude instances
const fs = require('fs');
const path = require('path');

function splitTasks(inputFile) {
    const content = fs.readFileSync(inputFile, 'utf8');
    const lines = content.split('\n');
    
    const tasks = {
        developer: [],
        reviewer: [],
        tester: [],
        documenter: []
    };
    
    let currentRole = 'developer';
    let currentTask = [];
    
    lines.forEach(line => {
        if (line.startsWith('## ROLE:')) {
            if (currentTask.length > 0) {
                tasks[currentRole].push(currentTask.join('\n'));
                currentTask = [];
            }
            currentRole = line.replace('## ROLE:', '').trim().toLowerCase();
        } else if (line.startsWith('## TASK:')) {
            if (currentTask.length > 0) {
                tasks[currentRole].push(currentTask.join('\n'));
            }
            currentTask = [line];
        } else {
            currentTask.push(line);
        }
    });
    
    // Save last task
    if (currentTask.length > 0) {
        tasks[currentRole].push(currentTask.join('\n'));
    }
    
    // Write individual task files
    Object.entries(tasks).forEach(([role, roleTasks]) => {
        const outputFile = path.join(__dirname, 'tasks', `${role}-tasks.md`);
        const content = `# Tasks for ${role}\n\n${roleTasks.join('\n\n')}`;
        fs.writeFileSync(outputFile, content);
        console.log(`Created: ${outputFile} (${roleTasks.length} tasks)`);
    });
}

// Run if called directly
if (require.main === module) {
    const inputFile = process.argv[2] || 'tasks/master-tasks.md';
    splitTasks(inputFile);
}

module.exports = { splitTasks };
EOF
    
    chmod +x "$COLLAB_DIR/split-tasks.js"
}

# Create communication protocol
create_communication_protocol() {
    cat > "$COLLAB_DIR/COMMUNICATION_PROTOCOL.md" << 'EOF'
# Claude Collaboration Communication Protocol

## Overview
Multiple Claude instances communicate through shared files and structured handoffs.

## Roles

### 1. Developer Claude
- Primary development work
- Creates feature branches
- Implements new features
- Writes initial tests

### 2. Reviewer Claude  
- Code review and quality assurance
- Security analysis
- Performance optimization suggestions
- Creates review reports

### 3. Tester Claude
- Comprehensive test creation
- Edge case identification
- Integration testing
- Test coverage analysis

### 4. Documenter Claude
- API documentation
- User guides
- Code comments
- Architecture diagrams

## Communication Flow

1. **Shared Context** (`shared-context/CONTEXT.md`)
   - Project overview
   - Current sprint goals
   - Architecture decisions
   - Coding standards

2. **Task Queue** (`tasks/`)
   - Individual task files per role
   - Priority markers
   - Dependencies

3. **Handoff Protocol** (`handoff/`)
   - Current work status
   - Blockers
   - Next steps
   - Questions for other roles

4. **Review Queue** (`reviews/`)
   - Code ready for review
   - Review feedback
   - Approval status

## File Watching
Each Claude instance watches specific directories:
- Developer: `tasks/developer-tasks.md`, `reviews/feedback-*.md`
- Reviewer: `handoff/ready-for-review-*.md`
- Tester: `handoff/ready-for-testing-*.md`
- Documenter: `handoff/ready-for-docs-*.md`

## Synchronization
- Use file timestamps for ordering
- Lock files to prevent conflicts
- Regular status updates every 15 minutes
EOF
}

# Create role-specific launch scripts
create_role_launchers() {
    # Developer Claude
    cat > "$COLLAB_DIR/launch-developer.sh" << 'EOF'
#!/bin/bash
ROLE="developer"
WORK_DIR="/Users/abhishek/Work/claude-automation/collaboration"

echo "Launching Developer Claude..."

claude -p "You are the Developer Claude in a multi-Claude collaboration system.

Your responsibilities:
1. Read tasks from $WORK_DIR/tasks/developer-tasks.md
2. Implement features in the main codebase
3. Write initial unit tests
4. Create handoff documents when ready for review

Communication:
- Read shared context from: $WORK_DIR/shared-context/CONTEXT.md
- When code is ready, create: $WORK_DIR/handoff/ready-for-review-[timestamp].md
- Check for feedback in: $WORK_DIR/reviews/feedback-*.md
- Update progress in: $WORK_DIR/handoff/CURRENT_WORK.md

Rules:
- Always create feature branches
- Commit frequently with clear messages
- Run tests before handoff
- Document complex logic inline

Start by reading your tasks and the shared context."
EOF
    
    # Reviewer Claude
    cat > "$COLLAB_DIR/launch-reviewer.sh" << 'EOF'
#!/bin/bash
ROLE="reviewer"
WORK_DIR="/Users/abhishek/Work/claude-automation/collaboration"

echo "Launching Reviewer Claude..."

# Use AppleScript to open Claude Desktop with specific instructions
osascript << 'END'
tell application "Claude"
    activate
    delay 2
    
    -- Create new conversation
    tell application "System Events"
        keystroke "n" using command down
        delay 1
        
        -- Type the reviewer prompt
        keystroke "You are the Reviewer Claude in a multi-Claude collaboration system.

Your responsibilities:
1. Monitor $WORK_DIR/handoff/ready-for-review-*.md
2. Perform thorough code reviews
3. Check for security issues, performance problems, and code smells
4. Create detailed feedback documents

Communication:
- Read code to review from: handoff/ready-for-review-*.md
- Write feedback to: reviews/feedback-[timestamp].md
- Mark approved code in: reviews/approved-[timestamp].md
- Suggest improvements and optimizations

Review Checklist:
- Code quality and readability
- Security vulnerabilities
- Performance bottlenecks
- Test coverage
- Documentation completeness
- Breaking changes
- Best practices adherence

Start by checking for any pending reviews."
    end tell
end tell
END
EOF
    
    # Tester Claude (using AI Studio)
    cat > "$COLLAB_DIR/launch-tester-aistudio.sh" << 'EOF'
#!/bin/bash
ROLE="tester"
WORK_DIR="/Users/abhishek/Work/claude-automation/collaboration"

echo "Launching Tester in Google AI Studio..."

# Create test prompt file
cat > "$WORK_DIR/tester-prompt.txt" << 'PROMPT'
You are the Tester AI in a multi-AI collaboration system.

Your responsibilities:
1. Monitor ready-for-testing files
2. Create comprehensive test suites
3. Identify edge cases
4. Write integration tests
5. Generate test reports

Working Directory: /Users/abhishek/Work/claude-automation/collaboration

Tasks:
- Read code from: handoff/ready-for-testing-*.md
- Write tests to: tests/generated/
- Create reports in: reviews/test-report-*.md

Focus on:
- Unit tests with high coverage
- Integration tests
- Edge case identification
- Performance testing scenarios
- Security test cases

Generate tests in JavaScript/Jest format.
PROMPT

# Open AI Studio in browser with instructions
open "https://aistudio.google.com"

echo "Please paste the contents of $WORK_DIR/tester-prompt.txt into AI Studio"
echo "Then upload any code files from the handoff directory"
EOF
    
    # Make all launchers executable
    chmod +x "$COLLAB_DIR/launch-developer.sh"
    chmod +x "$COLLAB_DIR/launch-reviewer.sh"
    chmod +x "$COLLAB_DIR/launch-tester-aistudio.sh"
}

# Create file watcher for automatic handoffs
create_file_watcher() {
    cat > "$COLLAB_DIR/watch-handoffs.js" << 'EOF'
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const WATCH_DIR = '/Users/abhishek/Work/claude-automation/collaboration/handoff';
const NOTIFICATION_SOUND = '/System/Library/Sounds/Glass.aiff';

// Watch for new handoff files
fs.watch(WATCH_DIR, (eventType, filename) => {
    if (eventType === 'rename' && filename) {
        const filepath = path.join(WATCH_DIR, filename);
        
        // Check file type and notify appropriate role
        if (filename.includes('ready-for-review')) {
            notify('Reviewer', 'New code ready for review!');
        } else if (filename.includes('ready-for-testing')) {
            notify('Tester', 'New code ready for testing!');
        } else if (filename.includes('ready-for-docs')) {
            notify('Documenter', 'New code ready for documentation!');
        }
        
        console.log(`New handoff detected: ${filename}`);
    }
});

function notify(role, message) {
    // macOS notification
    exec(`osascript -e 'display notification "${message}" with title "${role} Claude"'`);
    exec(`afplay ${NOTIFICATION_SOUND}`);
}

console.log(`Watching for handoffs in: ${WATCH_DIR}`);
console.log('Press Ctrl+C to stop...');
EOF
    
    chmod +x "$COLLAB_DIR/watch-handoffs.js"
}

# Create master orchestrator
create_orchestrator() {
    cat > "$COLLAB_DIR/orchestrate.sh" << 'EOF'
#!/bin/bash

# Master Orchestrator for Multi-Claude Collaboration

COLLAB_DIR="/Users/abhishek/Work/claude-automation/collaboration"

echo "🤖 Multi-Claude Orchestrator"
echo "=========================="

# Function to check if process is running
is_running() {
    pgrep -f "$1" > /dev/null
}

# Start file watcher
if ! is_running "watch-handoffs.js"; then
    echo "Starting handoff watcher..."
    node "$COLLAB_DIR/watch-handoffs.js" &
    WATCHER_PID=$!
    echo "Watcher PID: $WATCHER_PID"
fi

# Launch tmux session for monitoring
tmux new-session -d -s claude-collab

# Developer Claude in first pane
tmux send-keys -t claude-collab:0 "$COLLAB_DIR/launch-developer.sh" C-m

# Split for monitoring
tmux split-window -h -t claude-collab:0
tmux send-keys -t claude-collab:0.1 "watch -n 5 'ls -la $COLLAB_DIR/handoff/'" C-m

# Create new window for logs
tmux new-window -t claude-collab:1 -n logs
tmux send-keys -t claude-collab:1 "tail -f $COLLAB_DIR/logs/*.log" C-m

echo "✅ Orchestration started!"
echo ""
echo "Commands:"
echo "  View session:     tmux attach -t claude-collab"
echo "  Launch Reviewer:  $COLLAB_DIR/launch-reviewer.sh"
echo "  Launch Tester:    $COLLAB_DIR/launch-tester-aistudio.sh"
echo "  Stop all:         tmux kill-session -t claude-collab"
echo ""
echo "Collaboration directory: $COLLAB_DIR"
EOF
    
    chmod +x "$COLLAB_DIR/orchestrate.sh"
}

# Create example collaborative task
create_example_task() {
    cat > "$COLLAB_DIR/tasks/master-tasks.md" << 'EOF'
# Collaborative Development Task

## ROLE: developer
## TASK: Implement User Authentication
- Create JWT-based authentication system
- Implement login/logout endpoints
- Add password hashing with bcrypt
- Create user model and database schema
- Write basic unit tests

## ROLE: reviewer  
## TASK: Review Authentication Implementation
- Check for security vulnerabilities
- Verify JWT implementation
- Review password handling
- Check for SQL injection risks
- Validate error handling

## ROLE: tester
## TASK: Test Authentication System
- Create comprehensive test suite
- Test edge cases (invalid tokens, expired tokens)
- Test password requirements
- Create integration tests
- Test rate limiting

## ROLE: documenter
## TASK: Document Authentication API
- Create API endpoint documentation
- Write authentication flow diagram
- Document security considerations
- Create usage examples
- Write troubleshooting guide
EOF
}

# Main setup
main() {
    echo -e "${BLUE}🤖 Setting up Multi-Claude Collaboration System${NC}"
    echo "============================================="
    
    setup_collaboration
    create_task_splitter
    create_communication_protocol
    create_role_launchers
    create_file_watcher
    create_orchestrator
    create_example_task
    
    # Split the example tasks
    node "$COLLAB_DIR/split-tasks.js" "$COLLAB_DIR/tasks/master-tasks.md"
    
    echo -e "\n${GREEN}✅ Collaboration system ready!${NC}"
    echo -e "\nTo start collaboration:"
    echo -e "  1. Run: ${YELLOW}$COLLAB_DIR/orchestrate.sh${NC}"
    echo -e "  2. Launch additional Claudes as needed"
    echo -e "  3. Monitor progress in tmux session"
    echo -e "\nWithout using expensive APIs! 🎉"
}

main
