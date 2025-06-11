#!/bin/bash

# iTerm2 escape sequences for setting tab title
# This script tests different methods to set persistent tab titles

TITLE="$1"

if [ -z "$TITLE" ]; then
    echo "Usage: $0 <title>"
    exit 1
fi

echo "Testing iTerm2 title setting methods for: $TITLE"

# Method 1: Standard terminal title escape sequence
echo -ne "\033]0;${TITLE}\007"

# Method 2: iTerm2 specific escape sequence for tab title
echo -ne "\033]1;${TITLE}\007"

# Method 3: iTerm2 proprietary escape sequence
echo -ne "\033]6;1;bg;red;brightness;0\007"
echo -ne "\033]6;1;bg;green;brightness;0\007"
echo -ne "\033]6;1;bg;blue;brightness;0\007"

# Method 4: Set both window and tab title
echo -ne "\033]2;${TITLE}\007"

# Method 5: iTerm2 specific - set user-defined variable
echo -ne "\033]1337;SetUserVar=tabTitle=$(echo -n "$TITLE" | base64)\007"

echo "Title should now be: $TITLE"