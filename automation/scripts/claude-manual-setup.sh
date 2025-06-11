#!/bin/bash

# Manual instructions since automation is failing

cat << 'EOF'
=== MANUAL SETUP FOR CLAUDE TABS ===

Since automated tab creation isn't working properly, here's how to set it up manually:

1. CLOSE all existing iTerm tabs first

2. Open iTerm and create a new window

3. For EACH Claude session you want:
   
   a) Create new tab: Cmd+T
   
   b) In the new tab, type:
      tmux attach -t claude-main
   
   c) Once attached, press:
      Ctrl-b then the window number
      
      Window numbers:
      1 = palladio-191408
      2 = work-070959  
      3 = work-030125
      4 = work-161317
      5 = palladio-155426
      6 = claude-bob
      7 = claude-alice
      8 = automation-145822
      9 = test-web
      10 = test-web (use Ctrl-b ' then type 10)
      11 = palladio-215205 (use Ctrl-b ' then type 11)
   
   d) Right-click → Change Profile → Select color:
      - Palladio windows → "Palladio" profile
      - Work windows → "Work" profile
      - Automation → "Automation" profile

4. Save this window arrangement:
   Window → Save Window Arrangement → Name it "Claude Sessions"
   
5. Next time, restore with:
   Window → Restore Window Arrangement → Claude Sessions

=== ALTERNATIVE: Try tmux native tabs ===

Close everything and run this single command:
tmux -CC new-session -A -s claude-main

This uses iTerm2's native tmux integration.
EOF