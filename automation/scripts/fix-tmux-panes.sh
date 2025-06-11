#!/bin/bash

# Fix tmux pane layout issues

echo "🔧 Fixing tmux pane layouts..."

# For each window, ensure it's using full screen
for window in $(tmux list-windows -t claude-work -F '#I' 2>/dev/null || tmux list-windows -t claude-main -F '#I'); do
    # Select even pane layout (full screen)
    tmux select-layout -t $window even-horizontal 2>/dev/null || true
    tmux select-layout -t $window tiled 2>/dev/null || true
done

echo "✅ Pane layouts fixed"
echo ""
echo "If you see split panes in tmux:"
echo "  - Press Ctrl-b then Space (cycles layouts)"
echo "  - Or Ctrl-b then Alt-1 (even horizontal)"
echo "  - Or Ctrl-b then Alt-2 (even vertical)"