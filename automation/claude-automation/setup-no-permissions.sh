#!/bin/bash

# Add Claude No-Permissions Alias

echo "Setting up Claude no-permissions alias..."

# Add to shell config
cat >> ~/.zshrc << 'EOF'

# Claude No Permissions Alias
alias claude-np='claude --dangerously-skip-permissions'
alias cwork-np='/Users/abhishek/Work/claude-automation/claude-no-permissions.sh'

# Quick function for autonomous work
claude-auto() {
    local task_file="${1:-instructions/test-automation.md}"
    cd /Users/abhishek/Work/claude-automation
    
    echo "🚀 Starting Claude (NO PERMISSIONS MODE)"
    echo "Task: $task_file"
    
    claude --dangerously-skip-permissions -p "Read and complete all tasks in $task_file. Create PROGRESS.md and SUMMARY.md. Work autonomously."
}
EOF

echo "✅ Aliases added!"
echo ""
echo "🎯 Usage:"
echo ""
echo "1. Quick autonomous work:"
echo "   claude-np"
echo ""
echo "2. Work with task file:"
echo "   cwork-np"
echo "   # or"
echo "   claude-auto instructions/your-task.md"
echo ""
echo "3. Direct command:"
echo "   claude --dangerously-skip-permissions -p 'your prompt'"
echo ""
echo "⚠️  Note: This bypasses ALL permission checks!"
echo "   Only use in trusted environments."
echo ""
echo "Reload shell: source ~/.zshrc"
