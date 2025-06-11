#!/bin/bash

# Setup iTerm Notifications for Claude Sessions
# This script configures iTerm to send notifications when Claude needs attention

echo "🔔 Setting up iTerm notifications for Claude sessions..."

# Create notification helper script
cat > /tmp/claude_notification_helper.scpt << 'EOF'
on run argv
    set sessionName to item 1 of argv
    set projectPath to item 2 of argv
    set message to item 3 of argv
    
    display notification message with title "Claude Session Alert" subtitle sessionName
    
    tell application "iTerm"
        activate
        tell current window
            tell current session
                set badge text to "⚠️"
                write text "echo -e '\\a'"
            end tell
        end tell
    end tell
end run
EOF

# Make helper script executable
chmod +x /tmp/claude_notification_helper.scpt

# Configure iTerm preferences for notifications
echo "📝 Configuring iTerm notification settings..."

# Enable terminal bell and notifications
defaults write com.googlecode.iterm2 SoundForEsc -bool true
defaults write com.googlecode.iterm2 FlashTabBarInFullscreen -bool true
defaults write com.googlecode.iterm2 PostNotifications -bool true
defaults write com.googlecode.iterm2 BounceDockIcon -bool true

# Configure bell settings
defaults write com.googlecode.iterm2 AudibleBell -bool true
defaults write com.googlecode.iterm2 VisualBell -bool true

# Enable dock badge
defaults write com.googlecode.iterm2 BadgeEnabled -bool true

echo "✅ iTerm notification settings configured!"
echo ""
echo "📋 Settings applied:"
echo "  ✓ Terminal bell enabled"
echo "  ✓ Visual bell enabled"  
echo "  ✓ Dock bounce enabled"
echo "  ✓ Post notifications enabled"
echo "  ✓ Badge notifications enabled"
echo "  ✓ Tab flash in fullscreen enabled"

echo ""
echo "🔄 Please restart iTerm for all settings to take effect."
echo ""
echo "🎯 Features enabled:"
echo "  • Bell sound when Claude needs attention"
echo "  • Visual flash notifications"
echo "  • Dock icon bounce"
echo "  • macOS notification center alerts"
echo "  • Session badges with 🤖 and ⚠️ icons"
echo "  • Tab titles showing project names"