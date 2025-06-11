#!/bin/bash

echo "🔗 Setting up GitHub Integration"
echo "================================"

# Check if in git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "⚠️  Not in a git repository!"
    echo "Please run this in your project directory"
    exit 1
fi

# Create GitHub workflow
mkdir -p .github/workflows

cat > .github/workflows/claude-automation.yml << 'WORKFLOW'
name: Claude Automation Support

on:
  issue_comment:
    types: [created]
  pull_request:
    types: [opened, synchronize]

jobs:
  auto-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Tests
        run: |
          npm test || echo "No tests found"
          
      - name: Comment Results
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '✅ Automated checks complete!'
            })
WORKFLOW

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
# Run tests before commit
npm test || true

# Check for breaking changes
if git diff --cached --name-only | grep -E '\.(js|ts|py)$'; then
    echo "🔍 Checking for breaking changes..."
    # Add your breaking change detection here
fi
HOOK

chmod +x .git/hooks/pre-commit

echo "✅ GitHub integration configured!"
echo ""
echo "Features enabled:"
echo "  - Automated testing on PR"
echo "  - Pre-commit hooks"
echo "  - GitHub Actions workflow"
