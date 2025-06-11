#!/bin/bash

# Ultra-simple ca command

case "${1:-single}" in
    "all")
        echo "Opening multiple tabs is complex. For now, use single mode."
        echo "Then use Ctrl-b w to navigate between windows."
        ;;
    "single"|"s"|"")
        echo "Attaching to tmux session..."
        tmux attach -t claude-main || echo "No tmux session found. Run migration script first."
        ;;
    *)
        echo "Usage: ca [single|all]"
        echo "  ca single - Attach to tmux (default)"
        echo "  ca all    - Not implemented yet"
        ;;
esac