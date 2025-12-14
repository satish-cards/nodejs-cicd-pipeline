# GitHub Environments Setup Guide

## Overview

GitHub Environments allow you to configure deployment protection rules, secrets, and variables specific to each environment.

## Why Use GitHub Environments?

- **Protection Rules**: Require manual approval before production deployments
- **Environment-Specific Secrets**: Different secrets for staging vs production
- **Deployment History**: Track deployments per environment
- **Branch Restrictions**: Control which branches can deploy to which environments

## Creating Environments

### Step 1: Navigate to Repository Settings

1. Go to your GitHub repository
2. Click **Settings** tab
3. Click **Environments** in the left sidebar

### Step 2: Create Staging Environment

1. Click **New environment**
2. Name: `staging`
3. Click **Configure environment**
4. **Optional**: Add protection rules
   - Wait timer: 0 minutes (auto-deploy)
   - Required reviewers: None (or add if you want approval)
5. Click **Save protection rules**

### Step 3: Create Production Environment

1. Click **New environment**
2. Name: `production`
3. Click **Configure environment**
4. **Required**: Add protection rules
   - ✅ **Required reviewers**: Add yourself or team members
   - Wait timer: 0 minutes (or add delay if desired)
   - Deployment branches: `main` only
5. Click **Save protection rules**

## Environment Secrets (Optional)

If you need environment-specific secrets for GitHub Actions:

### Staging Secrets
1. Go to `staging` environment settings
2. Click **Add secret**
3. Add secrets like:
   - `STAGING_API_KEY`
   - `STAGING_DATABASE_URL`
   - etc.

### Production Secrets
1. Go to `production` environment settings
2. Click **Add secret**
3. Add secrets like:
   - `PRODUCTION_API_KEY`
   - `PRODUCTION_DATABASE_URL`
   - etc.

## Updating GitHub Actions Workflows

Your workflows are already configured to use environments:

### CD Staging Workflow
```yaml
# .github/workflows/cd-staging.yml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: staging  # Uses staging environment
```

### CD Production Workflow
```yaml
# .github/workflows/cd-production.yml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # Uses production environment (requires approval)
```

## Verification

After creating environments:

1. **Test Staging Deployment**:
   ```bash
   git add .
   git commit -m "Test staging deployment"
   git push origin main
   ```
   - Should deploy automatically to staging
   - Check Actions tab for workflow run

2. **Test Production Deployment**:
   - Manually trigger production workflow from Actions tab
   - Should show approval request
   - Approve and verify deployment

## Current Workflow Behavior

### Without GitHub Environments
- ✅ Staging: Deploys automatically on push to main
- ⚠️ Production: Workflow runs but no approval gate (not ideal)

### With GitHub Environments
- ✅ Staging: Deploys automatically on push to main
- ✅ Production: Requires manual approval before deployment

## Quick Setup Commands

No CLI commands needed - all done through GitHub UI:

1. Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/environments`
2. Create `staging` environment (no protection rules)
3. Create `production` environment (add required reviewers)
4. Done!

## Troubleshooting

### "Environment not found" error in Actions
- Make sure environment name matches exactly (case-sensitive)
- Check that environment is created in repository settings

### Approval not required for production
- Verify "Required reviewers" is configured in production environment
- Check that workflow specifies `environment: production`

### Can't create environments
- Environments are available for public repos and GitHub Pro/Team/Enterprise
- For free private repos, you may need to upgrade

## Next Steps

After setting up environments:
1. ✅ Test staging deployment
2. ✅ Test production approval workflow
3. ✅ Add environment-specific secrets if needed
4. ✅ Configure branch protection rules
5. ✅ Deploy ArgoCD production application

## References

- [GitHub Environments Documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Deployment Protection Rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#deployment-protection-rules)
