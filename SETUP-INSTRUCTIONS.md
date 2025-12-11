# Setup Instructions - Follow These Steps

## You Have Two Options:

### Option 1: Automated Setup (Recommended)
Run the setup script that will guide you through everything:

```bash
./setup-git.sh
```

The script will:
- Configure Git with your name and email
- Initialize the Git repository
- Create the initial commit
- Guide you through creating a GitHub repository
- Push your code to GitHub

---

### Option 2: Manual Setup (Step by Step)

Follow these commands one by one:

#### Step 1: Configure Git
```bash
# Set your name (replace with your actual name)
git config --global user.name "Your Name"

# Set your email (replace with your actual email)
git config --global user.email "your.email@example.com"

# Verify configuration
git config --list
```

#### Step 2: Initialize Git Repository
```bash
# Initialize Git
git init

# Check status
git status
```

#### Step 3: Create Initial Commit
```bash
# Stage all files
git add .

# Create commit
git commit -m "Initial commit: Node.js CI/CD pipeline project"

# Verify commit
git log --oneline
```

#### Step 4: Create GitHub Repository

**Go to GitHub and create a new repository:**

1. Open your browser and go to: https://github.com/new
2. Fill in the details:
   - **Repository name**: `nodejs-cicd-pipeline`
   - **Description**: `Complete CI/CD pipeline demonstration for Node.js`
   - **Visibility**: Choose Public or Private
   - **⚠️ IMPORTANT**: Do NOT check any boxes (no README, no .gitignore, no license)
3. Click "Create repository"

#### Step 5: Connect to GitHub and Push

After creating the repository on GitHub, you'll see a page with instructions. Use these commands:

```bash
# Add GitHub as remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/nodejs-cicd-pipeline.git

# Rename branch to main (if needed)
git branch -M main

# Push to GitHub
git push -u origin main
```

**Authentication Note:**
- If prompted for a password, you need to use a **Personal Access Token** (not your GitHub password)
- To create a token:
  1. Go to: https://github.com/settings/tokens
  2. Click "Generate new token (classic)"
  3. Give it a name like "CI/CD Pipeline"
  4. Select the `repo` scope
  5. Click "Generate token"
  6. Copy the token and use it as your password when pushing

#### Step 6: Verify CI Pipeline

1. Go to your repository on GitHub: `https://github.com/YOUR_USERNAME/nodejs-cicd-pipeline`
2. Click the "Actions" tab
3. You should see the "CI Pipeline" workflow running! 🎉

---

## Troubleshooting

### "Permission denied" when pushing

**Solution 1: Use Personal Access Token**
- Create a token at: https://github.com/settings/tokens
- Use the token as your password when prompted

**Solution 2: Use SSH instead**
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add ~/.ssh/id_ed25519

# Copy public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub: Settings → SSH and GPG keys → New SSH key

# Change remote to SSH
git remote set-url origin git@github.com:YOUR_USERNAME/nodejs-cicd-pipeline.git

# Try pushing again
git push -u origin main
```

### "Repository not found"

- Double-check your GitHub username in the remote URL
- Verify the repository exists on GitHub
- Check you have the correct permissions

### "Updates were rejected"

- The remote repository might have changes you don't have locally
- Try: `git pull origin main --rebase`
- Then: `git push -u origin main`

---

## What Happens After Push?

Once you successfully push to GitHub:

1. ✅ Your code is now on GitHub
2. ✅ GitHub Actions CI pipeline runs automatically
3. ✅ Tests, linting, and Docker build are executed
4. ✅ You can see the results in the "Actions" tab

## Next Steps

After successful setup:

1. **View your CI pipeline**: Go to Actions tab on GitHub
2. **Set up branch protection**: Follow `docs/branch-protection-setup.md`
3. **Create a test PR**: 
   ```bash
   git checkout -b test-feature
   echo "# Test" >> README.md
   git add README.md
   git commit -m "Test CI pipeline"
   git push origin test-feature
   ```
   Then create a Pull Request on GitHub

---

## Need Help?

- 📖 Detailed guide: `docs/git-github-setup.md`
- 📖 Quick start: `docs/QUICK-START.md`
- 📖 CI/CD docs: `docs/github-actions.md`

**You've got this! 🚀**
