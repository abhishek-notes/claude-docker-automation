#!/bin/bash

# Claude Automation System Startup Script
set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${BLUE}"
echo "🤖 Claude Automation System Startup"
echo "===================================="
echo -e "${NC}"

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check Node.js
    if ! command -v node >/dev/null 2>&1; then
        error "Node.js not found. Please install Node.js 16+ from https://nodejs.org"
        exit 1
    fi
    
    local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -lt 16 ]; then
        error "Node.js version 16+ required. Current: $(node --version)"
        exit 1
    fi
    
    info "✅ Node.js $(node --version) found"
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker not found. Please install Docker Desktop"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        error "Docker daemon not running. Please start Docker Desktop"
        exit 1
    fi
    
    info "✅ Docker is running"
    
    # Check Claude authentication
    if [ ! -f "$HOME/.claude.json" ]; then
        warn "Claude authentication not found at ~/.claude.json"
        warn "Make sure you're logged into Claude Code on your Mac"
    else
        info "✅ Claude authentication found"
    fi
}

# Install dependencies
install_dependencies() {
    if [ ! -d "node_modules" ]; then
        log "Installing Node.js dependencies..."
        npm install
        info "✅ Dependencies installed"
    else
        info "✅ Dependencies already installed"
    fi
}

# Build Docker image if needed
build_docker_image() {
    if ! docker image inspect claude-automation:latest >/dev/null 2>&1; then
        log "Building Claude Docker image..."
        ./claude-direct-task.sh help > /dev/null 2>&1 || {
            error "claude-direct-task.sh not executable or missing"
            exit 1
        }
        
        # Build using the existing Docker setup
        docker build -t claude-automation:latest .
        info "✅ Docker image built"
    else
        info "✅ Docker image already exists"
    fi
}

# Make scripts executable
make_executable() {
    log "Making scripts executable..."
    chmod +x *.sh 2>/dev/null || true
    info "✅ Scripts are executable"
}

# Start the system
start_system() {
    local port="${1:-3456}"
    
    log "Starting Claude Task Automation System on port $port..."
    
    # Check if port is already in use
    if lsof -i :$port >/dev/null 2>&1; then
        warn "Port $port is already in use"
        read -p "Kill existing process and restart? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            lsof -ti :$port | xargs kill -9 2>/dev/null || true
            sleep 2
        else
            error "Cannot start on port $port"
            exit 1
        fi
    fi
    
    echo ""
    info "🚀 Starting Claude Task Automation System..."
    info "📱 Web Interface: http://localhost:$port"
    info "⚡ API Server: http://localhost:$port/api"
    echo ""
    info "📋 Usage:"
    info "   1. Open http://localhost:$port in your browser"
    info "   2. Enter your project path and task description"
    info "   3. Click 'Improve Task Instructions'"
    info "   4. Click 'Launch Automated Task'"
    info "   5. Watch Claude work autonomously!"
    echo ""
    warn "Press Ctrl+C to stop the system"
    echo ""
    
    # Start the API server
    PORT=$port node task-api.js
}

# Show help
show_help() {
    cat << 'EOF'
Claude Automation System Startup

USAGE:
    ./start-system.sh [port]           Start the system on specified port (default: 3456)
    ./start-system.sh check            Check prerequisites only
    ./start-system.sh setup            Setup dependencies only
    ./start-system.sh help             Show this help

EXAMPLES:
    ./start-system.sh                  Start on port 3456
    ./start-system.sh 8080             Start on port 8080
    ./start-system.sh check            Check if system is ready
    ./start-system.sh setup            Install dependencies and build Docker

SYSTEM COMPONENTS:
    • Web Interface (task-launcher.html) - Create and launch tasks
    • API Server (task-api.js) - Backend for task execution
    • Claude Automation (claude-auto.sh) - Automated Claude runner
    • Docker Container (claude-automation:latest) - Isolated environment

REQUIREMENTS:
    • Node.js 16+
    • Docker Desktop
    • Claude Code authentication (~/.claude.json)
    • Available port (default: 3456)
EOF
}

# Main function
main() {
    case "${1:-start}" in
        "check")
            check_prerequisites
            info "✅ All prerequisites satisfied"
            ;;
        "setup")
            check_prerequisites
            make_executable
            install_dependencies
            build_docker_image
            info "✅ Setup complete"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        [0-9]*)
            # Port number provided
            check_prerequisites
            make_executable
            install_dependencies
            build_docker_image
            start_system "$1"
            ;;
        "start"|*)
            # Default start
            check_prerequisites
            make_executable
            install_dependencies
            build_docker_image
            start_system "${1:-3456}"
            ;;
    esac
}

# Run main function
main "$@"