#!/bin/bash

# Start system with Docker persistent containers support
# This is an alternative to start-system.sh that uses Docker containers

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
echo "🐳 Claude Docker Automation System"
echo "===================================="
echo -e "${NC}"

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

# Build Docker image if needed
if ! docker image inspect claude-automation:latest >/dev/null 2>&1; then
    log "Building Claude Docker image..."
    docker build -t claude-automation:latest .
    info "✅ Docker image built"
else
    info "✅ Docker image already exists"
fi

# Make scripts executable
chmod +x *.sh 2>/dev/null || true

# Show current containers
echo ""
info "📋 Current Claude Docker Containers:"
./claude-docker-persistent.sh list
echo ""

info "🚀 Docker Persistent Container System Ready!"
echo ""
echo -e "${BLUE}Usage Options:${NC}"
echo ""
echo "1. ${GREEN}Create New Persistent Container:${NC}"
echo "   ./claude-docker-persistent.sh start /path/to/project"
echo ""
echo "2. ${GREEN}List All Containers:${NC}"
echo "   ./claude-docker-persistent.sh list"
echo ""
echo "3. ${GREEN}Attach to Last Container:${NC}"
echo "   ./claude-docker-persistent.sh attach"
echo ""
echo "4. ${GREEN}Start Web Interface:${NC}"
echo "   ./start-system.sh"
echo "   (Enable Docker mode in web interface)"
echo ""
echo -e "${YELLOW}Key Features:${NC}"
echo "  🎨 Random colorful icons for easy identification"
echo "  📝 Smart keyword extraction for container names"
echo "  💾 Persistent containers (won't auto-start)"
echo "  🔄 Conversation history preserved"
echo ""
warn "Containers have restart=no policy (won't auto-start on Docker restart)"