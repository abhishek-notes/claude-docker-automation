#!/bin/bash

# Test iTerm2 profiles

echo "Testing iTerm2 Profiles..."
echo ""
echo "This will open 3 new tabs with different profiles."
echo "Press Enter to continue..."
read

osascript << 'EOF'
tell application "iTerm"
    activate
    
    tell current window
        -- Test Palladio profile
        create tab with profile "Palladio"
        tell current session
            write text "echo 'This should have a BLUE tint - Palladio Project'"
            write text "echo 'Check if the badge shows PALLADIO'"
        end tell
        
        -- Test Work profile
        create tab with profile "Work"
        tell current session
            write text "echo 'This should have a GREEN tint - Work Directory'"
            write text "echo 'Check if the badge shows WORK'"
        end tell
        
        -- Test Automation profile
        create tab with profile "Automation"
        tell current session
            write text "echo 'This should have a RED/ORANGE tint - Docker Automation'"
            write text "echo 'Check if the badge shows AUTO'"
        end tell
    end tell
end tell
EOF

echo ""
echo "✅ Opened test tabs with different profiles"
echo ""
echo "If the profiles don't exist or colors don't show:"
echo "1. Go to iTerm2 → Preferences → Profiles"
echo "2. Make sure you have created and named the profiles correctly"
echo "3. Adjust the background colors for each profile"