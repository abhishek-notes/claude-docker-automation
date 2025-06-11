#!/bin/bash

# Autonomous Claude Launcher - Actually Works!

HOURS=${1:-1}
TASK_FILE=${2:-"instructions/test-automation.md"}
PROJECT_DIR=${3:-"/Users/abhishek/Work/claude-automation"}

echo "🚀 Launching Claude (No Prompts Version)"
echo "======================================"
echo "Duration: $HOURS hours"
echo "Task file: $TASK_FILE"
echo "Project: $PROJECT_DIR"
echo ""

cd "$PROJECT_DIR"

# Create session info
SESSION_ID="session-$(date +%Y%m%d-%H%M%S)"
mkdir -p logs

# Create a script that Claude will run
cat > run-autonomous.sh << SCRIPT
#!/bin/bash
cd "$PROJECT_DIR"

# Create initial progress file
echo "# Progress Log" > PROGRESS.md
echo "Session started: \$(date)" >> PROGRESS.md
echo "" >> PROGRESS.md

# Read task file
echo "Reading tasks from: $TASK_FILE"
cat "$TASK_FILE"

echo ""
echo "Starting work..."

# The actual work would happen here
# For now, let's test file creation
echo "Testing file creation..."
echo "# Test File" > TEST_OUTPUT.md
echo "Created at: \$(date)" >> TEST_OUTPUT.md
echo "✅ File created successfully!" >> TEST_OUTPUT.md

echo "" >> PROGRESS.md
echo "- \$(date): Created TEST_OUTPUT.md" >> PROGRESS.md

echo "Work complete!"
SCRIPT

chmod +x run-autonomous.sh

# Launch in new terminal with auto-approval
osascript << APPLESCRIPT
tell application "Terminal"
    activate
    set newTab to do script "cd '$PROJECT_DIR' && echo 'Starting autonomous session...' && ~/claude-no-prompt < run-autonomous.sh"
end tell
APPLESCRIPT

echo ""
echo "✅ Claude launched in new Terminal!"
echo ""
echo "Check these files for results:"
echo "  - PROGRESS.md"
echo "  - TEST_OUTPUT.md"
echo ""
echo "If Claude STILL asks for permissions in the terminal:"
echo "  Just type: y"
echo "  Or press: Enter"
echo "  Keep pressing until it proceeds!"
