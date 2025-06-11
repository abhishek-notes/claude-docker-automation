#!/bin/bash

# Claude Collaboration Demo Script
# Demonstrates different collaboration approaches

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[DEMO]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
demo() { echo -e "${PURPLE}[COLLAB]${NC} $1"; }

show_demo_menu() {
    echo ""
    echo -e "${CYAN}🤝 Claude Collaboration System Demo${NC}"
    echo "=================================================="
    echo ""
    echo "Choose a collaboration approach:"
    echo ""
    echo "1. 📁 File-based Collaboration (Simple)"
    echo "   - Two Claude instances communicate via shared files"
    echo "   - Good for: Sequential tasks, document collaboration"
    echo ""
    echo "2. 🌐 Real-time Collaboration (Advanced)"
    echo "   - Live messaging between Claude instances"
    echo "   - Web dashboard for monitoring"
    echo "   - Good for: Complex analysis, real-time coordination"
    echo ""
    echo "3. 🧪 Test with Palladio Project"
    echo "   - Demo collaboration on your Palladio Software project"
    echo "   - One Claude analyzes backend, other analyzes frontend"
    echo ""
    echo "4. ❓ Show Collaboration Examples"
    echo "   - See example conversations between Claude instances"
    echo ""
    echo "5. 📚 Documentation & Help"
    echo "   - Complete guide to collaboration features"
    echo ""
    read -p "Enter your choice (1-5): " choice
    echo ""
    
    case $choice in
        1) demo_file_collaboration ;;
        2) demo_realtime_collaboration ;;
        3) demo_palladio_collaboration ;;
        4) show_collaboration_examples ;;
        5) show_collaboration_guide ;;
        *) echo "Invalid choice. Please run the demo again." ;;
    esac
}

demo_file_collaboration() {
    demo "Setting up file-based collaboration"
    
    local workspace="/tmp/claude-demo-file-collab"
    local project_path="${1:-/Users/abhishek/Work/palladio-software-25}"
    
    echo ""
    echo -e "${BLUE}This demo will:${NC}"
    echo "✅ Create shared workspace for two Claude instances"
    echo "✅ Setup communication files and protocols"
    echo "✅ Start Claude Alice (Backend Analyst)"
    echo "✅ Start Claude Bob (Frontend Specialist)"
    echo ""
    
    read -p "Press Enter to start the demo..."
    
    # Setup workspace
    ./claude-collaborative.sh setup "$workspace"
    
    echo ""
    demo "Workspace created at: $workspace"
    demo "Starting collaborative Claude instances..."
    echo ""
    
    # Start first instance
    echo -e "${YELLOW}Starting Claude Alice (Backend Analyst)...${NC}"
    echo "This will open in a new terminal window."
    echo ""
    
    osascript << EOF
tell application "Terminal"
    do script "cd '$PWD' && ./claude-collaborative.sh start alice '$project_path' '$workspace' 'Analyze backend architecture and Salesforce integration' 'Backend Architecture Analyst'"
end tell
EOF
    
    sleep 3
    
    echo -e "${YELLOW}Starting Claude Bob (Frontend Specialist)...${NC}"
    echo "This will open in another terminal window."
    echo ""
    
    osascript << EOF
tell application "Terminal"
    do script "cd '$PWD' && ./claude-collaborative.sh start bob '$project_path' '$workspace' 'Analyze frontend components and user experience' 'Frontend UI/UX Specialist'"
end tell
EOF
    
    echo ""
    demo "Both Claude instances are starting!"
    echo ""
    echo -e "${BLUE}What happens next:${NC}"
    echo "1. Both Claude instances will read the collaboration protocol"
    echo "2. They'll check for messages and update their status"
    echo "3. They'll begin analyzing different parts of your project"
    echo "4. They can ask each other questions via shared files"
    echo ""
    echo -e "${YELLOW}Monitor collaboration:${NC}"
    echo "./claude-collaborative.sh monitor $workspace"
    echo ""
    echo -e "${YELLOW}Check status:${NC}"
    echo "./claude-collaborative.sh status $workspace"
}

demo_realtime_collaboration() {
    demo "Setting up real-time collaboration with web dashboard"
    
    local workspace="/tmp/claude-demo-realtime"
    local project_path="${1:-/Users/abhishek/Work/palladio-software-25}"
    local port="8080"
    
    echo ""
    echo -e "${BLUE}This demo will:${NC}"
    echo "✅ Create collaboration server with web dashboard"
    echo "✅ Setup real-time messaging between Claude instances"
    echo "✅ Start two Claude instances with live communication"
    echo "✅ Show monitoring dashboard"
    echo ""
    
    read -p "Press Enter to start the real-time demo..."
    
    # Check if port is available
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        error "Port $port is in use. Stopping existing services..."
        ./claude-realtime-collab.sh cleanup 2>/dev/null || true
    fi
    
    echo ""
    demo "Setting up real-time collaboration server..."
    
    # Setup and start server
    ./claude-realtime-collab.sh setup "$workspace" "$port"
    ./claude-realtime-collab.sh start-server "$workspace" "$port" &
    
    sleep 5
    
    # Open dashboard
    echo ""
    demo "Opening collaboration dashboard..."
    open "http://localhost:$port"
    
    echo ""
    demo "Starting real-time Claude instances..."
    
    # Start instances in separate terminals
    osascript << EOF
tell application "Terminal"
    do script "cd '$PWD' && ./claude-realtime-collab.sh start alice '$project_path' '$workspace' 'Analyze system architecture and identify integration points' 'System Architect' $port"
end tell
EOF
    
    sleep 3
    
    osascript << EOF
tell application "Terminal"
    do script "cd '$PWD' && ./claude-realtime-collab.sh start bob '$project_path' '$workspace' 'Analyze user interfaces and experience flows' 'UX Analyst' $port"
end tell
EOF
    
    echo ""
    demo "🎉 Real-time collaboration is running!"
    echo ""
    echo -e "${BLUE}Features available:${NC}"
    echo "📊 Web Dashboard: http://localhost:$port"
    echo "💬 Real-time messaging between Claude instances"
    echo "📁 Live file sharing"
    echo "📈 Activity monitoring"
    echo ""
    echo -e "${YELLOW}Watch the dashboard to see:${NC}"
    echo "- Claude instances registering"
    echo "- Real-time message exchanges"
    echo "- Collaboration progress"
}

demo_palladio_collaboration() {
    demo "Collaborative analysis of Palladio Software project"
    
    local project_path="/Users/abhishek/Work/palladio-software-25"
    
    if [ ! -d "$project_path" ]; then
        error "Palladio project not found at: $project_path"
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}Palladio Software Collaboration Demo${NC}"
    echo ""
    echo "This demo will start two specialized Claude instances:"
    echo ""
    echo -e "${CYAN}🏗️  Claude Alpha (Backend Specialist):${NC}"
    echo "   - Analyze Medusa e-commerce backend"
    echo "   - Review Salesforce integration"
    echo "   - Check API layer and database design"
    echo ""
    echo -e "${CYAN}🎨 Claude Beta (Frontend Specialist):${NC}"
    echo "   - Analyze Next.js frontend architecture"
    echo "   - Review Strapi CMS integration"
    echo "   - Evaluate user experience and components"
    echo ""
    echo "They will collaborate to:"
    echo "✅ Identify integration issues"
    echo "✅ Suggest improvements"
    echo "✅ Create coordinated documentation"
    echo ""
    
    read -p "Start Palladio collaboration demo? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./claude-realtime-collab.sh start-pair "$project_path"
    fi
}

show_collaboration_examples() {
    echo ""
    echo -e "${CYAN}🤝 Claude Collaboration Examples${NC}"
    echo "======================================"
    echo ""
    
    echo -e "${BLUE}Example 1: Architecture Discussion${NC}"
    cat << 'EOF'
Claude Alice: I'm analyzing the Medusa backend. I found an interesting pattern 
              in the Salesforce integration. The sync happens in subscribers - 
              should this be moved to workflows for better error handling?

Claude Bob:   Good question! I'm seeing the frontend expects real-time updates. 
              The current subscriber pattern works but workflows would give us 
              better retry logic. What's the current failure rate?

Claude Alice: Looking at logs now... Found 3% failure rate on customer sync. 
              Workflows with proper error handling could reduce this.

Claude Bob:   Agreed. I can update the frontend to handle async workflows. 
              Should we implement a job queue for reliability?
EOF
    
    echo ""
    echo -e "${BLUE}Example 2: Code Review Collaboration${NC}"
    cat << 'EOF'
Claude Alice: Found potential security issue in API endpoint:
              /api/admin/salesforce-test/route.ts line 23
              Missing authentication check before Salesforce data access.

Claude Bob:   Confirmed. I see the frontend doesn't handle auth errors properly 
              either. Let me check the auth flow... 
              Frontend assumes user is always authenticated.

Claude Alice: I'll add proper middleware authentication.
              Can you add error handling for 401/403 responses?

Claude Bob:   On it! I'll also add loading states for better UX.
              Sharing updated component in /collaboration/shared/auth-handler.tsx
EOF
    
    echo ""
    echo -e "${BLUE}Example 3: Integration Problem Solving${NC}"
    cat << 'EOF'
Claude Alice: The Medusa-Salesforce sync is failing for products with 
              custom attributes. Error in salesforce.ts:145

Claude Bob:   I can see why - the frontend sends nested objects but 
              Salesforce expects flat structure. 
              Check the product form in components/ProductForm.tsx

Claude Alice: Found it! The form nests color/variant data. 
              I'll add a transformer function in the sync service.

Claude Bob:   Perfect! I'll update the form to match the expected structure.
              This should fix the sync issues.
EOF
    
    echo ""
    echo -e "${YELLOW}Key Collaboration Patterns:${NC}"
    echo "🔍 Cross-component analysis"
    echo "🛠️  Problem identification and solving"
    echo "📝 Code review and suggestions"
    echo "🔄 Coordinated improvements"
    echo "📋 Documentation collaboration"
    echo ""
}

show_collaboration_guide() {
    echo ""
    echo -e "${CYAN}📚 Complete Claude Collaboration Guide${NC}"
    echo "========================================"
    echo ""
    
    cat << 'EOF'
🎯 COLLABORATION APPROACHES

1. FILE-BASED COLLABORATION
   - Communication via shared markdown files
   - Question/answer format
   - Good for: Sequential tasks, documentation
   - Setup: ./claude-collaborative.sh

2. REAL-TIME COLLABORATION  
   - Live messaging between instances
   - Web dashboard monitoring
   - Shared state management
   - Good for: Complex analysis, coordination
   - Setup: ./claude-realtime-collab.sh

🛠️ SETUP COMMANDS

File-based:
  ./claude-collaborative.sh setup /tmp/workspace
  ./claude-collaborative.sh start-pair /path/to/project

Real-time:
  ./claude-realtime-collab.sh start-pair /path/to/project

🤝 COLLABORATION PROTOCOLS

Communication Structure:
- Clear question/response format
- Reference specific files and line numbers
- Update status regularly
- Share relevant code snippets

Message Types:
- question: Ask for help or clarification
- finding: Share discovery or insight  
- suggestion: Propose improvement
- status: Update current task progress

🔧 MONITORING & MANAGEMENT

File-based monitoring:
  ./claude-collaborative.sh monitor /workspace
  ./claude-collaborative.sh status

Real-time monitoring:
  Open http://localhost:8080
  View live dashboard

Cleanup:
  ./claude-collaborative.sh cleanup
  docker stop $(docker ps -q --filter name=claude-collab)

🎯 BEST PRACTICES

1. Define clear roles for each instance
2. Establish communication protocols early
3. Use specific, actionable questions
4. Reference code with file:line format
5. Update status regularly
6. Share findings and coordinate solutions

🚀 ADVANCED FEATURES

- Multiple instance coordination (3+ Claude instances)
- Integration with external tools (ChatGPT, Google AI)
- Apple Script automation for response passing
- Custom collaboration workflows
- Team development integration

EOF
    
    echo ""
    echo -e "${YELLOW}Ready to start collaborating?${NC}"
    echo "Run: ./claude-collab-demo.sh"
}

# Main execution
if [ $# -eq 0 ]; then
    show_demo_menu
else
    case "$1" in
        "file") demo_file_collaboration "${2:-}" ;;
        "realtime") demo_realtime_collaboration "${2:-}" ;;
        "palladio") demo_palladio_collaboration ;;
        "examples") show_collaboration_examples ;;
        "guide") show_collaboration_guide ;;
        *) show_demo_menu ;;
    esac
fi