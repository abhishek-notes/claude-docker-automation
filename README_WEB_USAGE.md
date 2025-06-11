# Claude Web Interface Usage Guide

## ✅ Current Working Solution

The web interface creates tasks and shows you exactly what to do, but requires one manual step due to Claude Code's Docker limitations.

### 🚀 How to Use:

#### 1. Start the Web Interface
```bash
./start-system.sh
```
Open: http://localhost:3456

#### 2. Create Your Task
1. **Project Path:** Enter `/Users/abhishek/Work/coin-flip-app` (or your project)
2. **Task Description:** Describe what you want Claude to build
3. **Click "Improve Task Instructions"** - Gets AI-enhanced task format
4. **Click "Launch Automated Task"** - This will:
   - Create the CLAUDE_TASKS.md file in your project
   - Start Claude in a Docker container
   - Show you the exact task to copy/paste

#### 3. Complete the Task (One Manual Step)
When the Docker container starts Claude:
1. **Claude will show a prompt** - you'll see "Copy/paste required"
2. **Copy the enhanced task** from the web interface
3. **Paste it into Claude**
4. **Claude works autonomously** from that point forward

### 🎯 Example Workflow:

1. **Web Interface:** Enter "Create a coin flip app with animation"
2. **Enhanced Task Generated:** Full structured task with requirements
3. **Claude Starts:** Container launches with Claude Code
4. **Copy/Paste:** One-time paste of the task into Claude
5. **Autonomous Work:** Claude completes everything automatically
6. **Results:** PROGRESS.md, SUMMARY.md, working code

### ⚡ Alternative: Direct Command Line

If you prefer, you can also run directly:
```bash
# This opens Claude directly with copy/paste prompt
./claude-direct-task.sh /Users/abhishek/Work/coin-flip-app

# This is the original working method
```

### 🔧 Why This Approach?

- **Claude Code** has rendering issues in non-interactive Docker environments
- **The web interface** creates perfect task files and handles all setup
- **Only one manual step** (copy/paste) is needed
- **Everything else is automated** (Docker, git, progress tracking)

### 🎉 Benefits:

- ✅ **Web interface** for easy task creation
- ✅ **AI-enhanced task instructions** 
- ✅ **Automatic Docker setup**
- ✅ **Real-time progress monitoring**
- ✅ **Automatic git workflow**
- ✅ **Professional result tracking**

This is currently the most reliable approach that combines the convenience of a web interface with the proven reliability of the copy/paste method.