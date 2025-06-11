#!/bin/bash

# Enhanced tmux configuration for many windows

cat >> ~/.tmux.conf << 'EOF'

# === Better Navigation for Many Windows ===

# Enable window list with preview
bind-key w choose-window -F '#{window_index}: #{window_name} - #{pane_current_command}'

# Quick jump to windows 10-20
bind-key M-0 select-window -t :10
bind-key M-1 select-window -t :11
bind-key M-2 select-window -t :12
bind-key M-3 select-window -t :13
bind-key M-4 select-window -t :14
bind-key M-5 select-window -t :15
bind-key M-6 select-window -t :16
bind-key M-7 select-window -t :17
bind-key M-8 select-window -t :18
bind-key M-9 select-window -t :19

# Search through windows
bind-key / command-prompt -p "search for:" "find-window '%%'"

# Group similar windows with prefixes
# This helps organize: palladio-*, work-*, automation-*
set-option -g allow-rename off

# Status bar shows more windows
set -g status-left-length 40
set -g status-right-length 60

# Window list format - shows first 10 and last 5
set -g window-status-format '#I:#W'
set -g window-status-current-format '#[bold]#I:#W*'

EOF

echo "✅ Enhanced tmux config for multiple windows"
echo ""
echo "New shortcuts added:"
echo "  Ctrl-b /     - Search for window by name"
echo "  Ctrl-b w     - Better window list with preview"
echo "  Alt-0 to 9   - Jump to windows 10-19"
echo ""
echo "Reload tmux config with: tmux source-file ~/.tmux.conf"