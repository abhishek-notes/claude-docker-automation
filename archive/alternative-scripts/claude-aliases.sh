# Claude Docker Automation Aliases and Functions
# Source this file in your ~/.zshrc

# Basic aliases
alias cda="cd /Users/abhishek/Work/claude-docker-automation"
alias claude-list="/Users/abhishek/Work/claude-docker-automation/claude-docker-tasks.sh list"
alias claude-attach="/Users/abhishek/Work/claude-docker-automation/claude-docker-tasks.sh attach"
alias claude-stop="/Users/abhishek/Work/claude-docker-automation/claude-docker-tasks.sh stop"
alias claude-web="/Users/abhishek/Work/claude-docker-automation/claude-docker.sh web"

# Main work function (renamed to avoid conflict)
claude_start() {
    /Users/abhishek/Work/claude-docker-automation/claude-docker-tasks.sh start "${1:-.}" "${2:-CLAUDE_TASKS.md}"
}

# Quick session starter
claude_quick() {
    /Users/abhishek/Work/claude-docker-automation/claude-docker-tasks.sh start "${1:-.}"
}

# Monitoring functions
claude_logs() {
    local project_name=$(basename "${1:-$(pwd)}")
    docker logs $(docker ps --filter name="claude-session-$project_name" --format "{{.Names}}" | head -1) 2>/dev/null | tail -50
}

claude_status() {
    echo "🐳 Docker Status:"
    docker ps --filter name="claude-session" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo "📊 System Resources:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | head -10
}

# Project helpers
claude_new_project() {
    local project_name="$1"
    local project_path="/Users/abhishek/Work/$project_name"
    
    if [ -z "$project_name" ]; then
        echo "Usage: claude-new-project <project-name>"
        return 1
    fi
    
    mkdir -p "$project_path"
    cd "$project_path"
    
    # Initialize git
    git init
    
    # Create basic task file
    cat > CLAUDE_TASKS.md << 'EOF'
# Project Tasks

## Project Overview
- **Goal**: [Describe the main objective]
- **Scope**: [Define what should be accomplished]

## Tasks to Complete

### 1. [Task Name]
- **Description**: [What needs to be done]
- **Requirements**: [Specific requirements]
- **Acceptance Criteria**: [What defines success]

## Technical Requirements
- [ ] Follow best practices
- [ ] Include tests
- [ ] Create documentation
- [ ] Use git properly

## Completion Criteria
The task is complete when:
- [ ] All requirements are met
- [ ] Tests pass
- [ ] Documentation is complete
- [ ] Code is working as specified
EOF
    
    git add CLAUDE_TASKS.md
    git commit -m "Initial commit: Add task specifications"
    
    echo "✅ Created new project: $project_path"
    echo "📝 Edit CLAUDE_TASKS.md with your requirements"
    echo "🚀 Run: claude_start $project_path"
}
