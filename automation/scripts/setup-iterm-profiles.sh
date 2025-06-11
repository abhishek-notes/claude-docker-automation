#!/bin/bash

# Create iTerm2 profiles for different project types

echo "Creating iTerm2 profiles for different Claude projects..."

# Create a profile configuration
cat > /tmp/iterm_claude_profiles.json << 'EOF'
{
  "Palladio Profile": {
    "Name": "Claude - Palladio",
    "Badge Text": "🏛️ PALLADIO",
    "Background Color": {
      "Red Component": 0.1,
      "Green Component": 0.1,
      "Blue Component": 0.15
    },
    "Badge Color": {
      "Red Component": 0.2,
      "Green Component": 0.4,
      "Blue Component": 0.8
    }
  },
  "Work Profile": {
    "Name": "Claude - Work",
    "Badge Text": "💼 WORK",
    "Background Color": {
      "Red Component": 0.1,
      "Green Component": 0.12,
      "Blue Component": 0.1
    },
    "Badge Color": {
      "Red Component": 0.2,
      "Green Component": 0.6,
      "Blue Component": 0.2
    }
  },
  "Automation Profile": {
    "Name": "Claude - Automation",
    "Badge Text": "🤖 AUTO",
    "Background Color": {
      "Red Component": 0.12,
      "Green Component": 0.1,
      "Blue Component": 0.1
    },
    "Badge Color": {
      "Red Component": 0.8,
      "Green Component": 0.2,
      "Blue Component": 0.2
    }
  }
}
EOF

echo ""
echo "To create different color profiles in iTerm2:"
echo ""
echo "1. In iTerm2 Preferences → Profiles"
echo "2. Click the '+' button at the bottom to create new profiles:"
echo ""
echo "   a) Create 'Claude - Palladio' profile:"
echo "      - Name: Claude - Palladio"
echo "      - Colors → Background: Dark blue tint"
echo "      - Session → Badge: Set to '🏛️ PALLADIO'"
echo ""
echo "   b) Create 'Claude - Work' profile:"
echo "      - Name: Claude - Work"
echo "      - Colors → Background: Dark green tint"
echo "      - Session → Badge: Set to '💼 WORK'"
echo ""
echo "   c) Create 'Claude - Automation' profile:"
echo "      - Name: Claude - Automation"
echo "      - Colors → Background: Dark red tint"
echo "      - Session → Badge: Set to '🤖 AUTO'"
echo ""
echo "3. Then in your tmux windows, you can:"
echo "   - Right-click → 'Change Profile' to switch"
echo "   - Or set profile when creating new windows"
