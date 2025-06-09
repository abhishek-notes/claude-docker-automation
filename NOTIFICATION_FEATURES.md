# iTerm Notification System for Claude Sessions

## ✅ Implemented Features

### 🔔 Notification Types
- **Terminal Bell**: Audible bell (`\a`) when Claude needs attention
- **macOS Notifications**: System notification center alerts  
- **iTerm Tab Names**: Descriptive tab titles showing project names
- **iTerm Window Activation**: Automatically brings iTerm to front
- **Session Monitoring**: Background process monitors Claude containers

### 🎯 iTerm Integration
- **Profile Support**: Uses your custom profiles (Palladio, Work, Automation)
- **Tab Management**: New tasks open in tabs, not new windows
- **Smart Fallback**: Falls back to default profile if specified profile doesn't exist
- **15-Second Delay**: Waits 15 seconds before pasting Claude prompts
- **Auto Enter**: Automatically presses Enter after pasting prompts

### 📊 Configuration Files
- `setup-iterm-notifications.sh` - Configure iTerm notification settings
- `claude-notification-trigger.sh` - Manual notification trigger
- `claude-terminal-launcher.sh` - Enhanced launcher with notifications
- `claude-direct-task.sh` - Main automation with monitoring

### 🔧 Environment Variables
- `CLAUDE_USE_TABS=true/false` - Controls tab vs window behavior
- `CLAUDE_ITERM_PROFILE="ProfileName"` - Sets iTerm profile

## 🚀 Usage Examples

### Basic Usage with Notifications
```bash
# Use Automation profile with notifications
export CLAUDE_ITERM_PROFILE="Automation"
./claude-terminal-launcher.sh /path/to/project CLAUDE_TASKS.md
```

### Different Profiles for Different Projects
```bash
# Palladio project
export CLAUDE_ITERM_PROFILE="Palladio"
./claude-terminal-launcher.sh /Users/abhishek/Work/palladio-software-25 CLAUDE_TASKS.md

# Work project  
export CLAUDE_ITERM_PROFILE="Work"
./claude-terminal-launcher.sh /Users/abhishek/Work/work-project CLAUDE_TASKS.md

# Automation project
export CLAUDE_ITERM_PROFILE="Automation"
./claude-terminal-launcher.sh /Users/abhishek/Work/claude-docker-automation CLAUDE_TASKS.md
```

### Manual Notifications
```bash
# Send custom notification
./claude-notification-trigger.sh "Claude needs your input!" "Project Name"
```

## 📋 How It Works

### 1. Session Launch
- Sets iTerm tab name to "Claude: ProjectName"
- Uses specified profile for colors/settings
- Waits 15 seconds then pastes task prompt
- Automatically presses Enter to submit

### 2. Background Monitoring
- Monitors Docker container while Claude is running
- Checks every 30 seconds for signs Claude is waiting
- Sends notification if Claude appears to need input
- Prevents spam with 5-minute cooldown

### 3. Notification Delivery
- **Bell**: Terminal bell sound
- **Visual**: macOS notification popup
- **iTerm**: Tab name updates to show attention needed
- **Activation**: Brings iTerm to foreground

## 🎛️ iTerm Settings Applied
- Terminal bell enabled
- Visual bell enabled
- Dock bounce enabled
- Post notifications enabled
- Tab flash in fullscreen enabled

## 🧪 Testing
```bash
# Test notification system
./test-notification-system.sh

# Test multiple profiles
./test-profiles-final.sh
```

## 📝 Logs
- Safety system logs: `logs/safety-system.log`
- Notification logs: `logs/notifications.log`

## 💡 Benefits
- **Never miss Claude prompts** - Bell and visual notifications
- **Multi-project support** - Different profiles for different projects  
- **Efficient workflow** - Tasks open in tabs, not separate windows
- **Automated monitoring** - Background process watches for attention needed
- **Customizable** - Use your existing iTerm profiles and preferences