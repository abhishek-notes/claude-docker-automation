#!/bin/bash

# Simplest approach using tmux -CC (control mode)

echo "🚀 Using iTerm2's native tmux integration..."

# First detach any existing connections
tmux detach-client -a 2>/dev/null || true

# Enable iTerm2 tmux integration if needed
defaults write com.googlecode.iterm2 UseNativeTmuxIntegration -bool true 2>/dev/null || true

echo ""
echo "Starting tmux in control mode..."
echo "This will open a new window with tabs for each tmux window"
echo ""

# Open in control mode - this should create tabs automatically
osascript <<'EOF'
tell application "iTerm"
  create window with default profile
  tell current session of current window
    write text "tmux -CC attach -t claude-main"
  end tell
end tell
EOF

echo ""
echo "✅ iTerm2 should now show all tmux windows as native tabs"
echo ""
echo "Tips:"
echo "  • Each tab = one tmux window"
echo "  • Window names appear in tab titles"
echo "  • To detach: Close the window or Cmd-D"