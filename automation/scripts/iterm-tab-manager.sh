#!/bin/bash

# Quick iTerm2 tab organizer for Claude sessions

case "${1:-help}" in
    "close-empty")
        # Close all tabs that aren't attached to Docker
        osascript << 'EOF'
tell application "iTerm"
    tell current window
        set tabList to tabs
        repeat with i from (count of tabList) to 1 by -1
            tell item i of tabList
                tell current session
                    if not (is processing) then
                        close
                    end if
                end tell
            end tell
        end repeat
    end tell
end tell
EOF
        echo "Closed empty tabs"
        ;;
        
    "arrange")
        # Arrange tabs by type (Palladio, Work, Automation)
        echo "Tab arrangement coming soon..."
        ;;
        
    "status")
        # Show status of all tabs
        osascript << 'EOF'
tell application "iTerm"
    set tabInfo to ""
    tell current window
        set tabCount to count of tabs
        set tabInfo to tabInfo & "Total tabs: " & tabCount & "\n\n"
        
        repeat with i from 1 to tabCount
            tell tab i
                set tabName to name
                tell current session
                    set isRunning to is processing
                    set sessionName to name
                end tell
                set tabInfo to tabInfo & "Tab " & i & ": " & sessionName
                if isRunning then
                    set tabInfo to tabInfo & " [ACTIVE]"
                else
                    set tabInfo to tabInfo & " [IDLE]"
                end if
                set tabInfo to tabInfo & "\n"
            end tell
        end repeat
    end tell
    return tabInfo
end tell
EOF
        ;;
        
    *)
        echo "iTerm2 Tab Manager for Claude"
        echo ""
        echo "Usage:"
        echo "  $0 status       - Show all tabs and their status"
        echo "  $0 close-empty  - Close tabs not running anything"
        echo "  $0 arrange      - Arrange tabs by project type"
        ;;
esac