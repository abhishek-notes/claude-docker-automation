#!/bin/bash

echo "🔧 Installing iTerm2 Nightly (fixing tmux -CC issue)..."
echo ""

# Option 1: Uninstall regular iTerm2 first
echo "Option 1: Replace iTerm2 with Nightly build"
echo "This will:"
echo "  - Remove regular iTerm2"
echo "  - Install iTerm2 nightly"
echo "  - Keep all your settings and profiles"
echo ""
echo "Commands to run:"
echo "  brew uninstall --cask iterm2"
echo "  brew install --cask iterm2@nightly"
echo ""

echo "Option 2: Use the working script instead (recommended)"
echo "Keep your current iTerm2 and use our fixed script"
echo ""
echo "Just run: ca"
echo ""

echo "Which option would you prefer?"
echo "1) Replace with nightly build"
echo "2) Keep current iTerm2 and use working script"
read -p "Enter choice (1 or 2): " choice

if [ "$choice" = "1" ]; then
    echo ""
    echo "Replacing iTerm2 with nightly build..."
    brew uninstall --cask iterm2
    brew install --cask iterm2@nightly
    echo ""
    echo "✅ Done! Open iTerm from Applications and run 'ca'"
else
    echo ""
    echo "✅ Using the working script solution"
    echo "Just run: ca"
fi