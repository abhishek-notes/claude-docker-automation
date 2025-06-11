# Claude Docker Sessions + tmux + iTerm2 Setup Issue

## Current Situation
I have 11 Claude Code instances running in Docker containers on macOS. I successfully migrated them all to a tmux session called "claude-main" with 11 windows (plus a dashboard). Everything works fine in tmux - I can navigate between windows using Ctrl-b w, attach to Docker containers, etc.

## The Goal
I want a command `ca` (alias) that opens all 11 tmux windows in separate iTerm2 tabs, with:
- Each tab showing its specific tmux window (not all showing the same window)
- Proper color profiles (I have iTerm2 profiles: "Palladio", "Work", "Automation")
- Each tab ready to show the Docker session for that window

## What's Working
1. Docker containers are running fine:
```
claude-session-palladio-software-25-20250608-191408
claude-session-Work-20250608-070959
claude-session-Work-20250608-030125
claude-session-Work-20250607-161317
claude-session-palladio-software-25-20250607-155426
claude-bob
claude-alice
claude-session-claude-docker-automation-20250607-145822
claude-session-test-web-claude-20250607-032259
claude-session-test-web-claude-20250607-031020
claude-session-palladio-software-25-20250606-215205
```

2. tmux session "claude-main" has windows:
- Window 0: dashboard
- Window 1: palladio-191408
- Window 2: work-070959
- Window 3: work-030125
- Window 4: work-161317
- Window 5: palladio-155426
- Window 6: claude-bob
- Window 7: claude-alice
- Window 8: automation-145822
- Window 9: test-web
- Window 10: test-web
- Window 11: palladio-215205

3. Single window mode works: `tmux attach -t claude-main`

## What's NOT Working
When trying to create an AppleScript to open all windows in tabs:

1. **Syntax Errors**: Getting AppleScript errors like:
   - "Expected end of line, etc. but found unknown token"
   - "syntax error: Expected """ but found unknown token"

2. **Wrong Behavior**: When it partially works:
   - All tabs show the same tmux window (usually window 0)
   - Numbers get typed into Claude Code interface instead of tmux
   - Creates dotted lines and resizes windows incorrectly

3. **Failed Approaches**:
   - Using `tmux attach -t claude-main \; select-window -t N`
   - Using `write text` in AppleScript to send numbers
   - Using System Events to send Ctrl-b keypresses

## Code That Didn't Work

```bash
# This created syntax errors
osascript << EOF
tell application "iTerm"
    tell current window
        create tab with profile "Palladio"
        tell current session
            write text "tmux attach -t claude-main \\; select-window -t 1"
        end tell
    end tell
end tell
EOF
```

## Environment
- macOS (Apple Silicon)
- iTerm2 (latest)
- tmux 3.5a
- zsh shell
- Docker Desktop

## Question
How can I create a working script that:
1. Opens iTerm2 with 11 tabs
2. Each tab connects to its specific tmux window (1-11)
3. Uses the correct iTerm2 profile for each tab
4. Doesn't have AppleScript syntax errors
5. Properly navigates to the right tmux window without typing into Claude Code

Please provide a complete, working solution that handles the escaping issues and tmux window selection properly. The key challenge seems to be getting each iTerm tab to show a different tmux window, not all showing the same one.