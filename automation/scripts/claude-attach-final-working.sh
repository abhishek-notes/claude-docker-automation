#!/bin/bash

# Claude attach command - choose your mode

case "${1:-colored}" in
    "cc"|"control"|"native")
        echo "Using iTerm2 native tmux integration (tmux -CC)..."
        ~/Work/claude-attach-cc.sh
        ;;
    
    "colored"|"color"|"c"|"")
        echo "Using color-coded tabs..."
        ~/Work/claude-attach-colored.sh
        ;;
    
    "single"|"s")
        echo "Using single window mode..."
        tmux attach -t claude-main
        ;;
    
    *)
        echo "Claude Attach (ca) - Choose your mode:"
        echo ""
        echo "  ca              - Color-coded tabs (default)"
        echo "  ca cc           - iTerm2 native control mode"  
        echo "  ca single       - Single tmux window"
        echo ""
        echo "Shortcuts:"
        echo "  ca c    = colored"
        echo "  ca s    = single"
        ;;
esac