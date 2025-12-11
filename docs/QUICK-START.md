# Quick Start Guide

Get your CI/CD pipeline up and running in 5 minutes!

## Step 1: Initialize Git (1 minute)

```bash
# Initialize Git repository
git init

# Configure Git (use your details)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Create initial commit
git add .
git commit -m "Initial commit: Node.js CI/CD pipeline"
```

## Step 2: Create GitHub Repository (2 minutes)

### Option A: GitHub Web Interface
1. Go to https://github.com/new
2. Name: `nodejs-cicd-pipeline`
3. **Don't** initialize with README
4. Click "Create repository"

### Option B: GitHub CLI (faster)
```bash
gh auth login
gh repo create nodejs-cicd-pipeline --public --source=. --remote=origin
```

## Step 3: Push to GitHub (1 minute)

```bash
# Connect to GitHub (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/nodejs-cicd-pipeline.git

# Push code
git branch -M main
git push -u origin main
```

## Step 4: Verify CI Pipeline (1 minute)

1. Go to your GitHub repository
2. Click "Actions" tab
3. Watch your CI pipeline run! 🎉

You should see:
- ✅ Install Dependencies
- ✅ Lint Code
- ✅ Run Tests with Coverage
- ✅ Build Docker Image
- ✅ CI Status Check

## What Just Happened?

Your code is now:
- ✅ Version controlled with Git
- ✅ Hosted on GitHub
- ✅ Automatically tested on every push
- ✅ Automatically linted for code quality
- ✅ Docker image built and tested

## Next Steps

### Test the CI Pipeline

Create a test branch and pull request:

```bash
# Create test branch
git checkout -b test-ci

# Make a small change
echo "# CI/CD Pipeline" >> README.md

# Commit and push
git add README.md
git commit -m "Test: Verify CI pipeline"
git push origin test-ci
```

Then:
1. Go to GitHub
2. Create Pull Request
3. Watch CI run automatically
4. Merge after CI passes

### Set Up Branch Protection

Protect your main branch:

```bash
# Go to: Repository Settings → Branches → Add rule
# Branch name pattern: main
# Enable: "Require status checks to pass before merging"
# Select: All CI jobs
```

Or follow the detailed guide: [Branch Protection Setup](branch-protection-setup.md)

## Common Commands

```bash
# Check status
git status

# Create feature branch
git checkout -b feature/my-feature

# Stage and commit changes
git add .
git commit -m "Add feature"

# Push to GitHub
git push origin feature/my-feature

# Run tests locally
npm test

# Run linting
npm run lint

# Start dev server
npm run dev
```

## Troubleshooting

### "Permission denied" when pushing
- Use Personal Access Token instead of password
- Or set up SSH keys (see [Git Setup Guide](git-github-setup.md))

### CI workflow not running
- Check `.github/workflows/ci.yml` exists
- Verify GitHub Actions is enabled in repo settings

### Tests failing in CI but passing locally
- Ensure all dependencies are in `package.json`
- Check Node.js version matches (18+)

## Need More Help?

- 📖 [Full Git and GitHub Setup Guide](git-github-setup.md)
- 📖 [GitHub Actions Documentation](github-actions.md)
- 📖 [Branch Protection Guide](branch-protection-setup.md)

## Success Checklist

- [ ] Git repository initialized
- [ ] GitHub repository created
- [ ] Code pushed to GitHub
- [ ] CI pipeline running successfully
- [ ] Branch protection configured (optional)
- [ ] Test PR created and merged

**Congratulations! Your CI/CD pipeline is live! 🚀**
