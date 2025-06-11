#!/bin/bash

# Fix the tmux windows to not close on keypress

TMUX_SESSION="claude-main"

echo "Fixing tmux windows to stay open after detaching..."

# Update each window's command
for window in $(tmux list-windows -t "$TMUX_SESSION" -F '#I:#W' | grep -v dashboard); do
    window_num=$(echo $window | cut -d: -f1)
    window_name=$(echo $window | cut -d: -f2)
    
    # Skip if someone is attached
    if tmux list-clients -t "$TMUX_SESSION:$window_num" 2>/dev/null | grep -q .; then
        echo "Skipping $window_name (someone attached)"
        continue
    fi
    
    echo "Updating window $window_num: $window_name"
    
    # Send better commands to the window
    tmux send-keys -t "$TMUX_SESSION:$window_num" C-c 2>/dev/null || true
    sleep 0.5
    
    tmux send-keys -t "$TMUX_SESSION:$window_num" "
echo -e '\\033[1;32mWindow fixed! This window will stay open.\\033[0m'
echo -e '\\033[1;33mCommands:\\033[0m'
echo '  Enter or \"a\" - Attach to Docker container'
echo '  \"exit\" - Close this window'
echo '  Ctrl-b w - List all windows'
echo ''
while true; do
    read -p 'Action (attach/exit): ' cmd
    case \"\$cmd\" in
        ''|'a'|'attach') 
            container=\$(docker ps --filter name=claude --format '{{.Names}}' | grep -i \"${window_name%%-*}\" | head -1)
            if [ -n \"\$container\" ]; then
                docker attach \"\$container\"
            else
                echo 'Container not found'
            fi
            ;;
        'exit') exit ;;
        *) echo 'Press Enter to attach, or type \"exit\" to close' ;;
    esac
done
" Enter
done

echo "✅ Fixed! Windows will now stay open after detaching."
echo ""
echo "Remember on Mac:"
echo "  • tmux uses Ctrl (not Cmd)"
echo "  • Ctrl-b w - Show all windows" 
echo "  • Ctrl-p Ctrl-q - Detach from Docker"