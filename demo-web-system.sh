#!/bin/bash

# Claude Web System Demo
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🎯 Claude Web System Demo${NC}"
echo "========================="
echo ""

# Start the web server
echo -e "${YELLOW}Starting web server...${NC}"
./start-system.sh 3459 &
WEB_PID=$!

# Wait for server to start
sleep 3

echo ""
echo -e "${GREEN}✅ System is ready!${NC}"
echo ""
echo -e "${BLUE}🌐 Web Interface:${NC} http://localhost:3459"
echo ""
echo -e "${YELLOW}📋 Quick Demo Steps:${NC}"
echo "1. Open the web interface in your browser"
echo "2. Project Path: /tmp/test-web-claude"
echo "3. Task: 'Create a simple HTML page that says Hello World'"
echo "4. Click 'Improve Task Instructions'"
echo "5. Click 'Launch in Terminal (Auto)'"
echo "6. Terminal will open with Claude running automatically!"
echo ""
echo -e "${BLUE}Features:${NC}"
echo "✅ Web interface for task creation"
echo "✅ AI-enhanced task instructions"
echo "✅ Automatic Terminal.app launch"
echo "✅ Auto-paste task into Claude"
echo "✅ Copy to clipboard button"
echo "✅ No TTY issues - runs in native Terminal"
echo ""
echo -e "${YELLOW}Press Enter when done to stop the demo...${NC}"
read

# Cleanup
echo "Stopping web server..."
kill $WEB_PID 2>/dev/null || true
echo "Demo complete!"