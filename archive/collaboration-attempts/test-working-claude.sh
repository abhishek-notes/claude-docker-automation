#!/bin/bash

# Test script to verify Claude instances are actually working

set -euo pipefail

COLLAB_DIR="/tmp/claude-collab-working"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[TEST]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

test_claude_working() {
    echo -e "${BLUE}🧪 Testing Claude Working System${NC}"
    echo "=================================="
    echo ""
    
    # Check if collaboration directory exists
    if [ ! -d "$COLLAB_DIR" ]; then
        error "Collaboration directory not found. Run: ./claude-working-system.sh demo"
        return 1
    fi
    
    log "Found collaboration directory: $COLLAB_DIR"
    
    # Check for running containers
    local containers=$(docker ps --filter name=claude-working --format "{{.Names}}" | wc -l)
    if [ "$containers" -eq 0 ]; then
        error "No Claude containers running. Run: ./claude-working-system.sh demo"
        return 1
    fi
    
    log "Found $containers running Claude instances"
    
    # List active instances
    echo ""
    info "Active Claude instances:"
    docker ps --filter name=claude-working --format "  {{.Names}} ({{.Status}})"
    
    # Check work outputs
    echo ""
    info "Checking work outputs..."
    
    for work_file in "$COLLAB_DIR/outputs"/*-work.md; do
        if [ -f "$work_file" ]; then
            local instance=$(basename "$work_file" -work.md)
            local lines=$(wc -l < "$work_file")
            local last_modified=$(stat -f %Sm "$work_file" 2>/dev/null || stat -c %y "$work_file" 2>/dev/null)
            
            if [ "$lines" -gt 1 ]; then
                log "✅ $instance is working ($lines lines, updated: $last_modified)"
                echo "   Latest work:"
                tail -3 "$work_file" | sed 's/^/     /'
            else
                warn "⚠️  $instance has minimal output ($lines lines)"
            fi
            echo ""
        fi
    done
    
    # Test sending a message
    echo ""
    info "Testing message delivery..."
    
    local test_instance=""
    for work_file in "$COLLAB_DIR/outputs"/*-work.md; do
        if [ -f "$work_file" ]; then
            test_instance=$(basename "$work_file" -work.md)
            break
        fi
    done
    
    if [ -n "$test_instance" ]; then
        local test_message="TEST: Please respond with 'RECEIVED TEST MESSAGE' in your work output."
        echo "" >> "$COLLAB_DIR/messages/${test_instance}-inbox.md"
        echo "## Test Message - $(date)" >> "$COLLAB_DIR/messages/${test_instance}-inbox.md"
        echo "$test_message" >> "$COLLAB_DIR/messages/${test_instance}-inbox.md"
        echo "" >> "$COLLAB_DIR/messages/${test_instance}-inbox.md"
        
        log "Test message sent to $test_instance"
        log "Check for response in: $COLLAB_DIR/outputs/${test_instance}-work.md"
        
        # Wait a moment and check for response
        echo ""
        info "Waiting 30 seconds for response..."
        sleep 30
        
        if grep -q "RECEIVED TEST MESSAGE" "$COLLAB_DIR/outputs/${test_instance}-work.md" 2>/dev/null; then
            log "✅ $test_instance responded to test message!"
        else
            warn "⚠️  No response from $test_instance yet (may take longer)"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}📊 Test Summary:${NC}"
    echo "  Containers running: $containers"
    echo "  Work files created: $(ls "$COLLAB_DIR/outputs"/*-work.md 2>/dev/null | wc -l)"
    echo "  Message files: $(ls "$COLLAB_DIR/messages"/*-inbox.md 2>/dev/null | wc -l)"
    echo ""
    echo -e "${YELLOW}💡 To interact with Claude instances:${NC}"
    echo "  ./claude-working-system.sh chat"
    echo "  ./claude-working-system.sh monitor"
    echo "  ./claude-working-system.sh status"
}

# Monitor for a few minutes to see if Claude is working
monitor_brief() {
    echo -e "${BLUE}📊 Brief monitoring (60 seconds)${NC}"
    echo "=================================="
    
    for i in {1..6}; do
        echo ""
        echo "Check $i/6 ($(date +%H:%M:%S)):"
        
        for work_file in "$COLLAB_DIR/outputs"/*-work.md; do
            if [ -f "$work_file" ]; then
                local instance=$(basename "$work_file" -work.md)
                local lines=$(wc -l < "$work_file")
                echo "  $instance: $lines lines"
                if [ $i -eq 6 ]; then
                    echo "    Latest:"
                    tail -2 "$work_file" | sed 's/^/      /'
                fi
            fi
        done
        
        if [ $i -lt 6 ]; then
            sleep 10
        fi
    done
    
    echo ""
    log "Monitoring complete. Claude instances should be actively working if set up correctly."
}

# Show how to verify Claude is working
show_verification_commands() {
    echo -e "${BLUE}🔍 How to Verify Claude is Working${NC}"
    echo "==================================="
    echo ""
    echo "1. Check work outputs:"
    echo "   cat $COLLAB_DIR/outputs/alice-work.md"
    echo "   cat $COLLAB_DIR/outputs/bob-work.md"
    echo ""
    echo "2. Send a test message:"
    echo "   ./claude-working-system.sh message alice 'What are you working on?'"
    echo ""
    echo "3. Interactive chat:"
    echo "   ./claude-working-system.sh chat"
    echo ""
    echo "4. Monitor in real-time:"
    echo "   ./claude-working-system.sh monitor"
    echo ""
    echo "5. Check Docker containers:"
    echo "   docker ps --filter name=claude-working"
    echo ""
    echo "6. View container logs:"
    echo "   docker logs claude-working-alice-[timestamp]"
}

# Main
case "${1:-test}" in
    "test")
        test_claude_working
        ;;
    "monitor")
        monitor_brief
        ;;
    "verify")
        show_verification_commands
        ;;
    *)
        test_claude_working
        ;;
esac