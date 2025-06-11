# 🗣️ How to Access Your Claude Conversations on Mac

## 📍 **Exact Locations on Your Mac**

### 🎯 **Main Storage** (Raw Conversation Files)
**Path**: `/Users/abhishek/Work/claude-conversations-exports/`
- **What**: 31+ conversation files in JSONL format
- **Size**: From 127B to 1.8MB each
- **Content**: Complete conversation history with Claude Code
- **Updated**: Automatically every time you use Claude

### 🗂️ **Backup Storage**
**Path**: `/Users/abhishek/Work/claude-conversations-backup/`
- **What**: Timestamped backups of Docker volumes
- **Purpose**: Recovery if main storage fails

---

## 🍎 **How to View on Mac**

### **Method 1: Finder (Easiest)**
```bash
open /Users/abhishek/Work/claude-conversations-exports
```
- Opens folder in Finder
- Browse files by date/size
- Double-click to open in text editor

### **Method 2: Terminal Viewer (Best)**
```bash
# Run the conversation viewer
./view-conversations.sh

# View a specific conversation
node parse-conversations.js /path/to/conversation.jsonl
```

### **Method 3: Spotlight Search**
1. Press `Cmd + Space`
2. Search: `claude-conversations-exports`
3. Open the folder result

### **Method 4: VS Code/Text Editor**
```bash
code /Users/abhishek/Work/claude-conversations-exports
```

---

## 📖 **Reading Conversations**

### **Raw Format** (JSONL files)
- One message per line in JSON format
- Contains full metadata and timestamps
- Machine-readable but harder to read

### **Parsed Format** (using our parser)
```bash
node parse-conversations.js filename.jsonl
```
- Clean, readable conversation format
- Shows: User messages → Claude responses
- Includes timestamps and message numbers

---

## 📊 **File Information**

### **Current Files** (as of June 9, 2025)
- **Total**: 31 conversation files
- **Largest**: `bd4a21f7-0b48-409e-a5b9-8a82b86237c4.jsonl` (1.8MB, 557 messages)
- **Most Recent**: Files updated June 9, 2025
- **Range**: From 127B (short chats) to 1.8MB (long sessions)

### **File Naming**
- Format: `{session-id}.jsonl`
- Example: `046b5ee1-06f4-40d8-aabf-1ea30990a91c.jsonl`
- Larger files = longer conversations
- Recent dates = current work

---

## 🔧 **Tools We Created**

### **1. Conversation Viewer** (`view-conversations.sh`)
- Lists all conversations with sizes/dates
- Shows example commands
- Mac Finder integration

### **2. Conversation Parser** (`parse-conversations.js`)
- Converts JSONL to readable format
- Handles Claude's complex response format
- Truncates very long messages

### **3. Auto-Backup System**
- Monitors Docker containers
- Exports conversations automatically
- Prevents data loss during crashes

---

## 🎯 **Quick Commands**

### **Browse All Conversations**
```bash
./view-conversations.sh
```

### **Open Folder in Finder**
```bash
open /Users/abhishek/Work/claude-conversations-exports
```

### **View Largest Conversation**
```bash
node parse-conversations.js /Users/abhishek/Work/claude-conversations-exports/bd4a21f7-0b48-409e-a5b9-8a82b86237c4.jsonl
```

### **Search Within Conversations**
```bash
grep -r "keyword" /Users/abhishek/Work/claude-conversations-exports/
```

---

## 🔄 **Ongoing Protection**

Your conversations are automatically:
- ✅ **Backed up** every 5 minutes during active sessions
- ✅ **Exported** from Docker volumes to safe storage
- ✅ **Preserved** even if Docker containers crash
- ✅ **Timestamped** for easy organization
- ✅ **Searchable** via Mac Spotlight and grep

**This session and all previous Claude conversations are permanently saved and easily accessible on your Mac!**