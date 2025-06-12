# Claude Docker Automation Task Template

## 🎯 PROJECT GOAL
[SPECIFIC_TASK_GOAL_HERE]

## Project Context
- Repository: [REPOSITORY_NAME]
- Project Path: [PROJECT_PATH]
- Session ID: [SESSION_ID]
- Branch Strategy: Always create feature branches from main, never commit directly to main
- GitHub Config: /Users/abhishek/Work/config/.env.github (GitHub classic token)
- Safety: Backup files before modification, track all changes

## 📋 METHODOLOGY - DOCUMENTATION FIRST APPROACH

### Phase 1: Documentation Discovery (READ FIRST, CODE LATER)
1. **Workspace Navigation**: Read /workspace/documentation/PROJECT_INDEX.md for workspace overview
2. **Project Type Recognition**:
   - **Palladio Software**: Read START_HERE_PALLADIO.md first
   - **Migration Projects**: Read README.md and MIGRATION_STRATEGY.md 
   - **Automation Projects**: Read relevant guides in /workspace/documentation/
   - **Analysis Projects**: Read SUMMARY.md for context
3. **Project-Specific Entry Points**:
   - Look for START_HERE_*.md files
   - Check docs/README.md for navigation
   - Review QUICK_REFERENCE_*.md files
4. **Focused Documentation Reading**: Based on task type, read only relevant documentation

### Phase 2: Selective Code Analysis (SCAN ONLY WHAT'S NEEDED)
- **For Palladio**: Focus on specific service/component directories, skip unrelated parts
- **For Migrations**: Analyze only transform_data.py, exports/, validation/ directories
- **For Automation**: Focus on relevant script directories and configuration files
- **Skip**: node_modules, build artifacts, unrelated codebases, database backups

## Rules & Constraints (CRITICAL - Follow Strictly)
- ⚠️ BACKUP before modifying any file (rename to .backup-TIMESTAMP)
- 📝 Document changes as needed (not mandatory for minor updates)
- 🚫 If breaking changes detected, create BREAKING_CHANGES.md and STOP
- ✅ Run tests for critical functionality only
- 🌿 Always create feature branch: claude/session-[SESSION_ID]
- 📋 Create PR description with all changes listed
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

### 🚨 CRITICAL FIRST STEP: UNDERSTAND THE TASK

**⚠️ DO NOT CREATE FILES FOR SIMPLE RESPONSES!**

Before taking ANY action, follow this decision flow:

```
┌─► Is this a simple response task? (greeting, calculation, one-line answer)
│   └─► YES → Output the response directly. DO NOT create files, branches, or commits!
│   └─► NO → Continue to task classification below
```

**Task Classification Guide:**
| Task Type | Detection Clues | Actions Allowed |
|-----------|----------------|-----------------|
| **Simple Response** | "respond with", "what is", "calculate" | Print answer only - NO files |
| **Analysis** | "explain", "audit", "review", "diagnose" | Read & report - NO modifications |
| **Implementation** | "create", "add", "implement", "build" | Full workflow - create files/code |
| **Fix/Update** | "fix", "update", "refactor", "change" | Modify specific files only |

### For Implementation Tasks:
1. 🔍 **Documentation-First Analysis**: Follow Phase 1 & 2 methodology above
2. 🌿 **Branch Creation**: Create feature branch claude/session-[SESSION_ID]
3. 💾 **Backup Phase**: Create backups of files before modification (as needed)
4. 🛠️ **Implementation**: Work systematically through each task
5. 🧪 **Testing**: Write tests for critical functionality (not everything needs tests)
6. 📝 **Documentation**: Update existing docs, create project-specific files
7. 🔄 **Git Workflow**: Commit frequently with clear messages
8. ✅ **Validation**: Verify functionality works as expected
9. 📋 **Summary**: Create project-appropriate completion documentation

## 📁 File Organization (Project-Specific, Not Root Dumping)
- **New projects**: Create a dedicated folder (project-name/) and organize all files within it
- **Existing projects**: Keep files within relevant project structure
- **Documentation**: Update existing docs rather than create unnecessary new ones
- **Progress tracking**: Create in project-specific location (e.g., project/PROGRESS.md)
- **Logs**: Use existing logging patterns where available
- **Never**: Create files in workspace root unless explicitly requested
- **⚠️ Warning**: Never create sibling directories that shadow existing package names (e.g., don't create `api/` if `src/api/` exists)

## 🎪 Deliverables (Preference-Based, Not Mandatory)
- **As Needed**: PROGRESS.md in project directory (for complex multi-step tasks)
- **Preferred**: SUMMARY.md for significant implementations
- **Optional**: CHANGELOG.md (only for major changes)
- **Context-Dependent**: Update existing documentation where it exists
- **Project-Specific**: Follow existing documentation patterns in the project

## 🚨 Testing Requirements (Smart Testing, Not Blanket Requirements)
- **Mandatory**: Tests for new critical functionality and bug fixes
- **Preferred**: Tests for complex business logic
- **Optional**: Tests for simple utility functions or minor updates
- **Context-Dependent**: Follow existing testing patterns in the project
- **Skip**: Don't require tests for documentation updates, configuration changes, or minor fixes

## 📖 Documentation Requirements (Contextual Updates)
- **Update existing**: Modify current documentation rather than create new files
- **API documentation**: Only for new or changed APIs
- **Code comments**: For complex logic (not everything needs comments)
- **README updates**: Only if project structure or usage changes significantly
- **Follow patterns**: Use existing documentation style and location

## Git Configuration
- Username: abhishek-notes
- Email: abhisheksoni1551@gmail.com
- Branch: claude/session-[SESSION_ID]
- Commit style: Use Conventional Commits format:
  - `feat:` New feature
  - `fix:` Bug fix
  - `docs:` Documentation only
  - `refactor:` Code change that neither fixes a bug nor adds a feature
  - `test:` Adding missing tests
  - `chore:` Changes to build process or auxiliary tools
- GitHub Token: Available at /Users/abhishek/Work/config/.env.github (GitHub classic token)

## 🏆 Success Criteria (Contextual Completion)
- ✅ All tasks from description are complete and working
- ✅ Critical functionality is tested (as needed, not blanket 80% coverage)
- ✅ Relevant documentation is updated (existing docs, not necessarily new files)
- ✅ Changes are appropriate for project context
- ✅ No breaking changes or properly documented if unavoidable
- ✅ Project-appropriate completion documentation created
- ✅ Files organized in correct project structure (not root dumping)

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

## 🛡️ Runtime Safety Rules
- **Filesystem**: Only modify files under /workspace unless explicitly requested
- **Dangerous Operations**: Never run `rm -rf /` or destructive commands without explicit permission
- **Network**: No external API writes or data uploads without explicit authorization
- **Secrets**: Keep all tokens/keys out of logs and commits
- **Database**: Prompt user before running migrations or schema changes
- **Production**: Never touch production systems unless explicitly authorized

**Remember: Safety first, quality always, document everything!**