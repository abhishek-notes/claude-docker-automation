# Update Task Alias

Your current `task` alias points to the old location. Please update it:

## Current Alias (needs updating):
```bash
alias task='cd /Users/abhishek/Work/claude-docker-automation && ./start-system.sh'
```

## New Alias (correct path):
```bash
alias task='cd /Users/abhishek/work/automation/claude-docker-automation && ./start-system.sh'
```

## How to Update:

1. Open your shell configuration file:
   ```bash
   # For zsh (default on macOS):
   nano ~/.zshrc
   
   # For bash:
   nano ~/.bash_profile
   ```

2. Find the current task alias and replace it with the new one

3. Reload your shell configuration:
   ```bash
   source ~/.zshrc
   # or
   source ~/.bash_profile
   ```

4. Test the alias:
   ```bash
   task
   ```

The task command will now properly launch your Claude automation system from the organized location.