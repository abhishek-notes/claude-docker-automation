# 🎯 Claude Code Profile Visual Identification Solution

## ❌ **Root Problem Identified**

You correctly identified the core issue: **Claude Code overwrites terminal settings**. When `claude --dangerously-skip-permissions` starts in Docker, it takes control of the terminal and applies its own settings, overriding any iTerm profiles we set initially.

## ✅ **Comprehensive Solution**

I've implemented a **multi-layered approach** that survives Claude Code taking over:

### 1. **iTerm2 Badges (Always Visible)**
- Each tab shows a persistent badge with the profile name
- Badges survive even when Claude Code changes terminal settings
- Visible in the corner of each terminal session

### 2. **Project Identifiers (For Auto-Switching)**
- Terminal outputs clear project identifiers before Claude starts:
  ```
  ==== PROJECT IDENTIFIER ====
  Project: /Users/abhishek/Work/palladio-software-25
  Profile: Palladio
  ==========================
  ```

### 3. **iTerm2 Automatic Profile Switching Setup**
Run the setup script:
```bash
./setup-iterm-profile-switching.sh
```

This guides you through configuring iTerm to automatically switch profiles based on project paths, even after Claude Code starts.

## 🔧 **How to Complete the Setup**

### Quick Solution (Immediate Results):
1. **Look for the badge** in each iTerm tab - it shows the profile name
2. **Check tab names** - they show `Claude: project-name [ProfileName]`
3. **Use Cmd+I** in any tab to manually change profile/colors

### Full Solution (Automatic):
1. **Run:** `./setup-iterm-profile-switching.sh`
2. **Follow the instructions** to configure automatic profile switching
3. **Set distinct colors** for each profile:
   - Palladio: Purple/magenta background
   - Work: Blue background  
   - Automation: Green background

## 🎨 **Visual Identification Features**

✅ **Persistent badges** showing profile names  
✅ **Clear tab naming** with project and profile info  
✅ **Project identifiers** output before Claude starts  
✅ **Automatic profile switching** based on project paths  
✅ **Manual override** capability (Cmd+I)  

## 🔍 **Testing**

The system now:
- ✅ Opens terminals correctly
- ✅ Sets initial profiles and badges
- ✅ Outputs project identifiers for auto-switching
- ✅ Provides visual identification even after Claude Code starts

Your insight about Claude Code overwriting terminals was key to solving this! The solution now works with Claude Code rather than fighting against it.