# Claude Docker Automation Task Template

## Project Context
- Repository: [REPOSITORY_NAME]
- Project Path: [PROJECT_PATH]
- Session ID: [SESSION_ID]
- Branch Strategy: Always create feature branches from main, never commit directly to main
- Testing: All code must have tests with >80% coverage
- Safety: Backup files before modification, track all changes

## Rules & Constraints (CRITICAL - Follow Strictly)
- ⚠️ BACKUP before modifying any file (rename to .backup-TIMESTAMP)
- 📝 Document all changes in CHANGELOG.md
- 🚫 If breaking changes detected, create BREAKING_CHANGES.md and STOP
- ✅ Run all tests after each change
- 🌿 Always create feature branch: claude/session-[SESSION_ID]
- 📋 Create PR description with all changes listed
- 🧪 Minimum 80% test coverage required
- 📖 Include API documentation for new endpoints
- 🔄 Commit frequently with meaningful messages

## Safety Protocol
- Create project backup before starting major changes
- Stop immediately if breaking changes are detected
- Document any blocking issues in ISSUES.md
- Never force-push or rewrite git history
- Verify all tests pass before declaring completion

## Communication Protocol
- Log progress every 30 minutes to logs/progress-$(date +%Y%m%d).log
- If stuck for >15 minutes, document the issue and continue
- Create summary report at completion in SUMMARY.md
- Document any external tool usage in logs/llm-interactions.log

## Working Instructions
1. 🔍 **Analysis Phase**: Understand project structure and requirements
2. 🌿 **Branch Creation**: Create feature branch claude/session-[SESSION_ID]
3. 💾 **Backup Phase**: Create backups of files before modification
4. 🛠️ **Implementation**: Work systematically through each task
5. 🧪 **Testing**: Write tests as you build (>80% coverage)
6. 📝 **Documentation**: Update docs and create PROGRESS.md
7. 🔄 **Git Workflow**: Commit frequently with clear messages
8. ✅ **Validation**: Run all tests and verify completion
9. 📋 **Summary**: Create comprehensive SUMMARY.md

## File Structure Requirements
- logs/progress-$(date +%Y%m%d).log - Progress tracking
- PROGRESS.md - Task completion status
- SUMMARY.md - Final completion report
- ISSUES.md - Any blocking problems encountered
- CHANGELOG.md - All changes documented
- BREAKING_CHANGES.md - If breaking changes detected

## Testing Requirements
- Unit tests for all new functions/methods
- Integration tests for API endpoints
- E2E tests for user workflows
- Performance tests if applicable
- All edge cases and error conditions tested

## Documentation Requirements
- API documentation with examples
- Code comments for complex logic
- README updates if needed
- Migration guides for breaking changes
- Architecture decisions recorded

## Git Configuration
- Username: abhishek-notes
- Email: abhisheksoni1551@gmail.com
- Branch: claude/session-[SESSION_ID]
- Commit style: "feat/fix/docs: Clear description"

## Completion Criteria
- ✅ All tasks from description are complete
- ✅ All tests pass with >80% coverage
- ✅ Documentation is updated
- ✅ CHANGELOG.md reflects all changes
- ✅ No breaking changes or documented properly
- ✅ SUMMARY.md confirms successful completion
- ✅ All files backed up before modification

## Emergency Protocols
- If breaking changes detected: STOP, document in BREAKING_CHANGES.md
- If tests fail: Fix immediately before continuing
- If stuck >15 minutes: Document in ISSUES.md, try alternative approach
- If external dependencies needed: Document requirements clearly

## External Tool Access Guidelines
- Can use package managers (npm, pip, yarn) for dependencies
- Git operations for version control
- Testing frameworks as needed
- Documentation generators
- Code formatters and linters
- NO external network calls during development
- Document all tool usage in logs/llm-interactions.log

**Remember: Safety first, quality always, document everything!**