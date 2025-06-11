#!/bin/bash

# Quick Test Script for Claude Automation System
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🧪 Quick Test - Claude Automation System${NC}"
echo "========================================"
echo ""

# Test 1: Check files exist
echo -e "${YELLOW}Test 1: Checking core files...${NC}"
files=("claude-auto.sh" "task-api.js" "web/task-launcher.html" "package.json" "start-system.sh")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file missing${NC}"
        exit 1
    fi
done

# Test 2: Check executables
echo ""
echo -e "${YELLOW}Test 2: Checking executables...${NC}"
if [ -x "claude-auto.sh" ]; then
    echo -e "${GREEN}✅ claude-auto.sh is executable${NC}"
else
    echo -e "${RED}❌ claude-auto.sh not executable${NC}"
    chmod +x claude-auto.sh
    echo -e "${GREEN}✅ Made claude-auto.sh executable${NC}"
fi

if [ -x "start-system.sh" ]; then
    echo -e "${GREEN}✅ start-system.sh is executable${NC}"
else
    echo -e "${RED}❌ start-system.sh not executable${NC}"
    chmod +x start-system.sh
    echo -e "${GREEN}✅ Made start-system.sh executable${NC}"
fi

# Test 3: Check Node.js
echo ""
echo -e "${YELLOW}Test 3: Checking Node.js...${NC}"
if command -v node >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Node.js $(node --version) found${NC}"
else
    echo -e "${RED}❌ Node.js not found${NC}"
    exit 1
fi

# Test 4: Install dependencies if needed
echo ""
echo -e "${YELLOW}Test 4: Checking dependencies...${NC}"
if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}Installing Node.js dependencies...${NC}"
    npm install
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo -e "${GREEN}✅ Dependencies already installed${NC}"
fi

# Test 5: Check Docker
echo ""
echo -e "${YELLOW}Test 5: Checking Docker...${NC}"
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker is running${NC}"
    else
        echo -e "${RED}❌ Docker daemon not running${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Docker not found${NC}"
    exit 1
fi

# Test 6: Check Docker image
echo ""
echo -e "${YELLOW}Test 6: Checking Docker image...${NC}"
if docker image inspect claude-automation:latest >/dev/null 2>&1; then
    echo -e "${GREEN}✅ claude-automation:latest image exists${NC}"
else
    echo -e "${YELLOW}⚠️  Building claude-automation:latest image...${NC}"
    docker build -t claude-automation:latest .
    echo -e "${GREEN}✅ Docker image built${NC}"
fi

# Test 7: Create test directory
echo ""
echo -e "${YELLOW}Test 7: Creating test project...${NC}"
TEST_DIR="/tmp/claude-test-project"
if [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
fi
mkdir -p "$TEST_DIR"

cat > "$TEST_DIR/CLAUDE_TASKS.md" << 'EOF'
# Test Task for Claude Automation

## Project Overview
- **Goal**: Create a simple "Hello World" HTML page
- **Type**: Web Development Test
- **Time Estimate**: 5 minutes

## Tasks

### 1. Create HTML File
- **Description**: Create a basic HTML page with "Hello from Claude!"
- **Requirements**: 
  - Valid HTML5 structure
  - Include a title
  - Add some basic styling
- **Acceptance Criteria**: Working HTML page that displays the message

### 2. Test the Page
- **Description**: Verify the HTML page works
- **Requirements**: Open in browser or validate HTML
- **Acceptance Criteria**: Page displays correctly

## Technical Requirements
- [ ] Use proper HTML5 structure
- [ ] Include basic CSS styling
- [ ] Create meaningful git commits

## Deliverables
- [ ] Working HTML page
- [ ] PROGRESS.md with status
- [ ] SUMMARY.md with results

Simple test to verify Claude automation is working!
EOF

echo -e "${GREEN}✅ Test project created at $TEST_DIR${NC}"

echo ""
echo -e "${GREEN}🎉 All tests passed! System is ready.${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Start the system: ${YELLOW}./start-system.sh${NC}"
echo "2. Open browser: ${YELLOW}http://localhost:3456${NC}"
echo "3. Test with project: ${YELLOW}$TEST_DIR${NC}"
echo ""
echo -e "${BLUE}Or test directly:${NC}"
echo "${YELLOW}./claude-auto.sh $TEST_DIR${NC}"