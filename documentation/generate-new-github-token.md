# Generate New GitHub Token

Your current token appears to be invalid or expired. Follow these steps to create a new one:

## Steps to Generate a New Classic Token:

1. **Go to GitHub Settings**
   - Visit: https://github.com/settings/tokens
   - Or navigate: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Generate New Token**
   - Click "Generate new token" → "Generate new token (classic)"
   - Give it a descriptive name like "Claude Docker Automation"

3. **Select Scopes** (minimum required):
   - ✅ `repo` - Full control of private repositories
   - ✅ `workflow` - Update GitHub Action workflows (if needed)
   - ✅ `read:org` - Read org and team membership (if using org repos)

4. **Generate and Copy**
   - Click "Generate token"
   - **IMPORTANT**: Copy the token immediately (you won't see it again!)

5. **Update Your Token File**
   ```bash
   # Edit the token file
   nano /workspace/.env.github
   
   # Or use this command (replace YOUR_NEW_TOKEN with actual token)
   cat > /workspace/.env.github << 'EOF'
   # GitHub Authentication
   GITHUB_TOKEN=YOUR_NEW_TOKEN
   GH_TOKEN=YOUR_NEW_TOKEN
   GITHUB_USERNAME=abhishek-notes
   EOF
   ```

6. **Test the New Token**
   ```bash
   # Load new token
   source /workspace/.env.github
   
   # Test it
   ./setup-github-token.sh
   ```

## Token Format
A valid classic token should:
- Start with `ghp_`
- Be followed by 36 alphanumeric characters
- Example: `ghp_1234567890abcdefghijklmnopqrstuvwxyz`

## Security Notes
- Never share your token
- Store it only in `.env.github` (which is gitignored)
- Rotate tokens regularly
- Use minimal required permissions