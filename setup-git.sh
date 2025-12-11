#!/bin/bash

# Git and GitHub Setup Script
# This script will help you set up Git and push your project to GitHub

set -e  # Exit on error

echo "=========================================="
echo "Git and GitHub Setup for CI/CD Pipeline"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Configure Git
echo -e "${BLUE}Step 1: Configure Git${NC}"
echo "--------------------------------------"

# Check if git user.name is set
if ! git config --global user.name > /dev/null 2>&1; then
    echo -e "${YELLOW}Git user name not configured.${NC}"
    read -p "Enter your name (e.g., John Doe): " git_name
    git config --global user.name "$git_name"
    echo -e "${GREEN}✓ Git user name set to: $git_name${NC}"
else
    current_name=$(git config --global user.name)
    echo -e "${GREEN}✓ Git user name already set to: $current_name${NC}"
fi

# Check if git user.email is set
if ! git config --global user.email > /dev/null 2>&1; then
    echo -e "${YELLOW}Git user email not configured.${NC}"
    read -p "Enter your email (e.g., john@example.com): " git_email
    git config --global user.email "$git_email"
    echo -e "${GREEN}✓ Git user email set to: $git_email${NC}"
else
    current_email=$(git config --global user.email)
    echo -e "${GREEN}✓ Git user email already set to: $current_email${NC}"
fi

echo ""

# Step 2: Initialize Git Repository
echo -e "${BLUE}Step 2: Initialize Git Repository${NC}"
echo "--------------------------------------"

if [ -d .git ]; then
    echo -e "${GREEN}✓ Git repository already initialized${NC}"
else
    git init
    echo -e "${GREEN}✓ Git repository initialized${NC}"
fi

echo ""

# Step 3: Create .gitignore check
echo -e "${BLUE}Step 3: Verify .gitignore${NC}"
echo "--------------------------------------"

if [ -f .gitignore ]; then
    echo -e "${GREEN}✓ .gitignore file exists${NC}"
else
    echo -e "${YELLOW}⚠ .gitignore file not found (this is unusual)${NC}"
fi

echo ""

# Step 4: Stage all files
echo -e "${BLUE}Step 4: Stage Files for Commit${NC}"
echo "--------------------------------------"

git add .
echo -e "${GREEN}✓ All files staged${NC}"

# Show what will be committed
echo ""
echo "Files to be committed:"
git status --short

echo ""

# Step 5: Create initial commit
echo -e "${BLUE}Step 5: Create Initial Commit${NC}"
echo "--------------------------------------"

if git rev-parse HEAD > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Repository already has commits${NC}"
    git log --oneline -1
else
    git commit -m "Initial commit: Node.js CI/CD pipeline project"
    echo -e "${GREEN}✓ Initial commit created${NC}"
fi

echo ""
echo ""

# Step 6: GitHub Setup Instructions
echo -e "${BLUE}Step 6: Create GitHub Repository${NC}"
echo "--------------------------------------"
echo ""
echo "Now you need to create a repository on GitHub:"
echo ""
echo "Option A: Using GitHub Web Interface"
echo "  1. Go to: https://github.com/new"
echo "  2. Repository name: nodejs-cicd-pipeline"
echo "  3. Description: Complete CI/CD pipeline demonstration for Node.js"
echo "  4. Choose Public or Private"
echo "  5. ⚠️  DO NOT initialize with README, .gitignore, or license"
echo "  6. Click 'Create repository'"
echo ""
echo "Option B: Using GitHub CLI (if installed)"
echo "  Run: gh auth login"
echo "  Then: gh repo create nodejs-cicd-pipeline --public --source=. --remote=origin"
echo ""
echo -e "${YELLOW}Press Enter after you've created the GitHub repository...${NC}"
read -p ""

echo ""

# Step 7: Add remote and push
echo -e "${BLUE}Step 7: Connect to GitHub and Push${NC}"
echo "--------------------------------------"

# Check if remote already exists
if git remote get-url origin > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Remote 'origin' already configured${NC}"
    echo "Remote URL: $(git remote get-url origin)"
else
    echo ""
    read -p "Enter your GitHub username: " github_username
    
    echo ""
    echo "Choose authentication method:"
    echo "  1. HTTPS (recommended - use Personal Access Token)"
    echo "  2. SSH (requires SSH key setup)"
    read -p "Enter choice (1 or 2): " auth_choice
    
    if [ "$auth_choice" = "2" ]; then
        remote_url="git@github.com:${github_username}/nodejs-cicd-pipeline.git"
    else
        remote_url="https://github.com/${github_username}/nodejs-cicd-pipeline.git"
    fi
    
    git remote add origin "$remote_url"
    echo -e "${GREEN}✓ Remote 'origin' added: $remote_url${NC}"
fi

echo ""

# Ensure we're on main branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    git branch -M main
    echo -e "${GREEN}✓ Renamed branch to 'main'${NC}"
fi

echo ""
echo -e "${YELLOW}Pushing to GitHub...${NC}"
echo ""

if [ "$auth_choice" = "1" ]; then
    echo "⚠️  If prompted for password, use a Personal Access Token instead:"
    echo "   1. Go to: https://github.com/settings/tokens"
    echo "   2. Generate new token (classic)"
    echo "   3. Select 'repo' scope"
    echo "   4. Copy the token and use it as your password"
    echo ""
fi

# Push to GitHub
if git push -u origin main; then
    echo ""
    echo -e "${GREEN}✓ Successfully pushed to GitHub!${NC}"
else
    echo ""
    echo -e "${YELLOW}⚠ Push failed. This might be due to authentication issues.${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. For HTTPS: Use Personal Access Token as password"
    echo "  2. For SSH: Ensure SSH key is added to GitHub"
    echo "  3. Try running: git push -u origin main"
    echo ""
    exit 1
fi

echo ""
echo ""
echo "=========================================="
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Your repository is now on GitHub!"
echo ""
echo "Next steps:"
echo "  1. Go to: https://github.com/${github_username}/nodejs-cicd-pipeline"
echo "  2. Click the 'Actions' tab"
echo "  3. Watch your CI pipeline run automatically! 🎉"
echo ""
echo "To set up branch protection:"
echo "  - Read: docs/branch-protection-setup.md"
echo "  - Or go to: Repository Settings → Branches → Add rule"
echo ""
echo "Happy coding! 🚀"
