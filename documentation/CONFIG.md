# Workspace Configuration & Claude Rules

**Last Updated**: 2025-06-10
**Purpose**: Git/GitHub configuration and Claude Code working rules for this workspace

---

## 🔧 GitHub Configuration

### Authentication
```bash
export GH_TOKEN="your_github_token_here"
export GITHUB_TOKEN="your_github_token_here"
export GITHUB_USERNAME="abhishek-notes"
```

### Repository Settings
- **Default Branch**: `main`
- **Primary Remote**: `origin`
- **Organization**: `abhishek-notes`

---

## 🤖 Claude Code Working Rules

### Project Structure Rules

1. **ALWAYS** consult `PROJECT_INDEX.md` first before working on any project
2. **NEVER** modify files in `.git` directories
3. **PRESERVE** all existing Git repositories in subdirectories
4. **USE** the main project structure: `/Users/abhishek/work/palladio-software-25/` for primary development

### Palladio Software 25 Component Rules

1. **Frontend** (`solace-medusa-starter/`):
   - Next.js 14+ application
   - TypeScript required
   - Use existing UI component patterns
   - Follow React hooks patterns

2. **Backend** (`palladio-store/`):
   - Medusa v2 e-commerce platform
   - Node.js/TypeScript
   - Follow Medusa plugin architecture
   - Respect database migrations

3. **CMS** (`palladio-store-strapi/`):
   - Strapi v4 headless CMS
   - Custom content types in `/src/api/`
   - Follow Strapi plugin conventions

4. **CRM** (`Pal-dev/`):
   - Salesforce integration layer
   - APEX/JavaScript hybrid
   - Follow Salesforce governance limits
   - Test in sandbox first

5. **API Layer** (`api-layer-2/`):
   - MedusaJS-Salesforce bridge
   - RESTful API design
   - Proper error handling
   - Rate limiting awareness

### Development Workflow Rules

1. **Branch Strategy**:
   - Create feature branches from `main`
   - Use descriptive branch names: `feature/component-description`
   - Never commit directly to `main`

2. **Commit Standards**:
   - Use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
   - Include affected component in scope: `feat(frontend): add new product grid`
   - Write clear, descriptive commit messages

3. **File Organization**:
   - Keep Claude automation scripts in `/automation/`
   - Store backups in `/backups/`
   - Archive old projects in `/Archives/`
   - Document everything in respective README files

### Security & Safety Rules

1. **NEVER** expose API keys or tokens in code
2. **ALWAYS** use environment variables for sensitive data
3. **VALIDATE** all user inputs in frontend and backend
4. **SANITIZE** data before Salesforce integration
5. **BACKUP** before major structural changes

### Claude Code Behavior Rules

1. **Research First**: Always read existing documentation before making changes
2. **Ask Context**: Use PROJECT_INDEX.md to understand project relationships
3. **Preserve Integrity**: Never break existing functionality
4. **Document Changes**: Update relevant README files when modifying structure
5. **Test Thoroughly**: Verify changes don't break existing workflows

### Technology Stack Guidelines

1. **Frontend**: React, Next.js, TypeScript, Tailwind CSS
2. **Backend**: Node.js, Medusa, PostgreSQL, Redis
3. **CMS**: Strapi, SQLite/PostgreSQL
4. **CRM**: Salesforce APEX, JavaScript, REST APIs
5. **DevOps**: Docker, GitHub Actions, Vercel/Railway

### Error Handling Standards

1. **Frontend**: Use error boundaries and proper state management
2. **Backend**: Implement comprehensive try-catch blocks
3. **API**: Return consistent error response formats
4. **Salesforce**: Handle governor limits and bulk operations
5. **Logging**: Use structured logging for debugging

### Performance Guidelines

1. **Frontend**: Implement lazy loading and code splitting
2. **Backend**: Use database indexes and query optimization  
3. **API**: Implement caching and rate limiting
4. **Salesforce**: Batch operations and avoid SOQL in loops
5. **Images**: Optimize and use CDN when possible

---

## 📁 Directory Structure Rules

### Root Level (`/Users/abhishek/work/`)
- Keep only essential navigation files: `PROJECT_INDEX.md`, `CONFIG.md`
- Main project folder: `palladio-software-25/`
- Support folders: `claude-automation/`, `Archives/`, backup folders

### Project Level (`/Users/abhishek/work/palladio-software-25/`)
- Each component in its own subdirectory
- Shared utilities in `/shared/` or `/common/`
- Documentation in component-specific README files
- Environment files at component level

### Component Level
- Follow each technology's best practices
- Maintain consistent naming conventions
- Include component-specific documentation
- Keep configuration files organized

---

## 🔍 Debugging & Troubleshooting

### Common Issues
1. **Port Conflicts**: Check running processes before starting services
2. **Database Issues**: Verify connection strings and migrations
3. **Salesforce Limits**: Monitor API usage and governor limits
4. **Build Failures**: Check dependency versions and Node.js compatibility

### Debug Tools
- **Frontend**: React DevTools, Next.js built-in debugger
- **Backend**: Node.js debugger, Medusa CLI tools
- **Database**: pgAdmin, Redis CLI
- **Salesforce**: Developer Console, Workbench

---

## 📋 Regular Maintenance Tasks

### Weekly
- Review and update dependencies
- Check for security vulnerabilities
- Clean up old branches and backups
- Update documentation

### Monthly  
- Review performance metrics
- Update Salesforce sandbox data
- Audit access permissions
- Review and update this configuration

---

## 🚨 Emergency Procedures

### Data Recovery
1. Check backup folders for recent backups
2. Use Git history for code recovery
3. Salesforce has 15-day recycle bin
4. Database backups stored in component directories

### System Rollback
1. Use Git to revert to last known good state
2. Check Docker containers for service issues
3. Verify environment variables and configurations
4. Test each component independently

---

**Remember**: This workspace contains active production systems. Always test changes in development environments first and follow proper deployment procedures.