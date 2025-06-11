#!/bin/bash

# Test script to verify window switching works

echo "Testing tmux window switching..."

# Method 1: Using select-window after attach
echo "Method 1: Run these two commands in a new terminal:"
echo "tmux attach -t claude-main"
echo "Then press: Ctrl-b 1"
echo ""

# Method 2: Using send-keys to switch
echo "Method 2: Let's try sending the window switch command:"
tmux send-keys -t claude-main:0 C-b 1

echo ""
echo "Check if window 0 (dashboard) switched to window 1"