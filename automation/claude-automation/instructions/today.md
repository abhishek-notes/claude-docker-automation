# Task Instructions for Claude Code

## Project Context
- Repository: [YOUR_REPO_NAME]
- Branch Strategy: Always create feature branches, never commit to main
- Testing: All code must have tests with >80% coverage

## Today's Tasks
1. [TASK 1 DESCRIPTION]
   - Requirements: [SPECIFIC REQUIREMENTS]
   - Expected outcome: [WHAT SUCCESS LOOKS LIKE]
   - Time estimate: [HOURS]

2. [TASK 2 DESCRIPTION]
   - Requirements: [SPECIFIC REQUIREMENTS]
   - Expected outcome: [WHAT SUCCESS LOOKS LIKE]
   - Time estimate: [HOURS]

## Rules & Constraints
- BACKUP before modifying any file (rename to .backup-TIMESTAMP)
- Document all changes in CHANGELOG.md
- If breaking changes detected, create BREAKING_CHANGES.md and stop
- Run all tests after each change
- Create PR description with all changes listed

## Communication Protocol
- Log progress every 30 minutes to logs/progress-[DATE].log
- If stuck for >15 minutes, document the issue and move to next task
- Create summary report at completion

## External Tool Access
- Can use ChatGPT API for: code reviews, documentation
- Can use Google AI for: test generation, optimization suggestions
- Document all LLM interactions in logs/llm-interactions.log
