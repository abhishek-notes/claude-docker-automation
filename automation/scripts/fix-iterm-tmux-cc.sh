#!/bin/bash

# Fix tmux -CC issue by upgrading iTerm2 to nightly build

echo "🔧 Fixing tmux -CC issue with iTerm2 nightly build..."
echo ""

# Check current iTerm2 version
echo "Current iTerm2 version:"
defaults read /Applications/iTerm.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "Unable to detect"
echo ""

# Install iTerm2 nightly
echo "Installing iTerm2 nightly build..."
brew install --cask iterm2-nightly

echo ""
echo "✅ iTerm2 nightly installed!"
echo ""
echo "Next steps:"
echo "1. Quit ALL iTerm2 windows (Cmd-Q)"
echo "2. Open iTerm2-nightly from Applications"
echo "3. Run: ca"
echo ""
echo "The nightly build fixes the tmux 3.5 compatibility issue."
echo "Your profiles and settings will be preserved."