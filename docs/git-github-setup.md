# Git and GitHub Setup Guide

This guide will help you set up Git version control and GitHub for your CI/CD pipeline project.

## Prerequisites

- Git installed on your system
- GitHub account (free account is sufficient)

## Step 1: Verify Git Installation

Check if Git is installed:

```bash
git --version
```

If not installed, download from: https://git-scm.com/downloads

## Step 2: Configure Git

Set your name and email (used for commits):

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

Verify configuration:

```bash
git config --list
```

## Step 3: Initialize Local Git Repository

From your project root directory:

```bash
# Initialize Git repository
git init

# Check status
git status
```

## Step 4: Create Initial Commit

Add all files and create your first commit:

```bash
# Stage all files
git add .

# Create initial commit
git commit -m "Initial commit: Node.js CI/CD pipeline project"

# Verify commit
git log
```

## Step 5: Create GitHub Repository

### Option A: Via GitHub Web Interface

1. Go to https://github.com
2. Click the "+" icon in top right → "New repository"
3. Fill in repository details:
   - **Repository name**: `nodejs-cicd-pipeline` (or your preferred name)
   - **Description**: "Complete CI/CD pipeline demonstration for Node.js"
   - **Visibility**: Public or Private (your choice)
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
4. Click "Create repository"

### Option B: Via GitHub CLI

If you have GitHub CLI installed:

```bash
# Login to GitHub
gh auth login

# Create repository
gh repo create nodejs-cicd-pipeline --public --source=. --remote=origin

# Or for private repository
gh repo create nodejs-cicd-pipeline --private --source=. --remote=origin
```

## Step 6: Connect Local Repository to GitHub

After creating the GitHub repository, connect your local repo:

```bash
# Add GitHub as remote origin (replace with your username/repo)
git remote add origin https://github.com/YOUR_USERNAME/nodejs-cicd-pipeline.git

# Verify remote
git remote -v

# Push to GitHub
git branch -M main
git push -u origin main
```

## Step 7: Verify GitHub Actions

After pushing, GitHub Actions should automatically run:

1. Go to your repository on GitHub
2. Click the "Actions" tab
3. You should see the "CI Pipeline" workflow running
4. Click on the workflow run to see details

## Step 8: Set Up Branch Protection (Optional but Recommended)

Follow the [Branch Protection Setup Guide](branch-protection-setup.md) to:
- Require CI checks to pass before merging
- Require pull request reviews
- Protect the main branch from direct commits

## Common Git Commands

### Daily Workflow

```bash
# Check status
git status

# Stage changes
git add .                    # Stage all changes
git add src/server.js        # Stage specific file

# Commit changes
git commit -m "Add feature X"

# Push to GitHub
git push origin main
```

### Working with Branches

```bash
# Create and switch to new branch
git checkout -b feature/new-feature

# List branches
git branch

# Switch branches
git checkout main

# Push branch to GitHub
git push origin feature/new-feature

# Delete branch (after merging)
git branch -d feature/new-feature
```

### Pull Requests

```bash
# Create feature branch
git checkout -b feature/add-metrics

# Make changes and commit
git add .
git commit -m "Add Prometheus metrics endpoint"

# Push to GitHub
git push origin feature/add-metrics

# Then create PR on GitHub web interface
```

## Troubleshooting

### Authentication Issues

If you get authentication errors when pushing:

**Option 1: Use Personal Access Token (Recommended)**

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with `repo` scope
3. Use token as password when prompted

**Option 2: Use SSH**

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub: Settings → SSH and GPG keys → New SSH key

# Change remote to SSH
git remote set-url origin git@github.com:YOUR_USERNAME/nodejs-cicd-pipeline.git
```

### Large Files Warning

If you see warnings about large files:

```bash
# Check .gitignore includes node_modules
echo "node_modules/" >> .gitignore

# Remove node_modules if accidentally staged
git rm -r --cached node_modules
git commit -m "Remove node_modules from tracking"
```

### Merge Conflicts

If you encounter merge conflicts:

```bash
# Pull latest changes
git pull origin main

# Resolve conflicts in your editor
# Look for <<<<<<< HEAD markers

# After resolving
git add .
git commit -m "Resolve merge conflicts"
git push origin main
```

## GitHub Actions Secrets

For future tasks (like pushing to container registry), you'll need to add secrets:

1. Go to repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add secrets as needed (e.g., `GHCR_TOKEN`)

## Next Steps

After setting up Git and GitHub:

1. ✅ Verify CI workflow runs successfully
2. ✅ Set up branch protection rules
3. ✅ Create a feature branch to test the workflow
4. ✅ Create a pull request to see CI in action
5. ✅ Proceed to next task: GitHub Container Registry integration

## Useful Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Docs](https://docs.github.com)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)

## Testing Your Setup

Create a test branch and PR to verify everything works:

```bash
# Create test branch
git checkout -b test-ci-workflow

# Make a small change
echo "# Testing CI" >> README.md

# Commit and push
git add README.md
git commit -m "Test: Verify CI workflow"
git push origin test-ci-workflow

# Create PR on GitHub
# Watch CI run automatically
# Merge PR after CI passes
```

## Summary

You now have:
- ✅ Git repository initialized
- ✅ GitHub repository created
- ✅ Local and remote connected
- ✅ CI/CD workflow ready to run
- ✅ Branch protection configured (optional)

Your CI/CD pipeline will now automatically run on every push and pull request!
