# Production Deployment Guide

## Overview

This guide explains how to deploy to production using the GitHub Actions CD workflow with manual approval and automatic rollback capabilities.

## Prerequisites

1. **Successful staging deployment**: Verify the application works correctly in staging
2. **GitHub environment configured**: Production environment with required reviewers set up
3. **Image tag identified**: Know the commit SHA or version tag to deploy

## Setting Up Production Environment Protection

Before your first production deployment, configure GitHub environment protection:

### Step 1: Create Production Environment

1. Go to your repository on GitHub
2. Click **Settings** → **Environments**
3. Click **New environment**
4. Name it exactly: `production`
5. Click **Configure environment**

### Step 2: Configure Protection Rules

1. **Enable Required reviewers**:
   - Check "Required reviewers"
   - Add team members who can approve deployments
   - Minimum 1 reviewer required

2. **Set deployment timeout** (optional):
   - The workflow has a built-in 24-hour timeout
   - You can add additional environment-level timeout if needed

3. **Set environment URL** (optional):
   - Add your production URL: `https://production.yourdomain.com`
   - This will be displayed in deployment logs

4. Click **Save protection rules**

## Deployment Process

### Step 1: Identify Image to Deploy

First, find the image tag from a successful staging deployment:

1. Go to **Actions** tab
2. Find the successful "CD - Staging Deployment" run
3. Note the commit SHA (short form shown in summary)
4. Or use the full commit SHA from the Git history

Example: `a1b2c3d` or full SHA `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0`

### Step 2: Trigger Production Deployment

1. Go to **Actions** tab in your GitHub repository
2. Click **CD - Production Deployment** in the left sidebar
3. Click **Run workflow** button (top right)
4. Fill in the form:
   - **Branch**: `main` (usually)
   - **Image tag**: Enter the commit SHA from staging (e.g., `a1b2c3d4e5f6...`)
   - **Reason**: Describe why you're deploying (e.g., "Deploy new user authentication feature")
5. Click **Run workflow**

### Step 3: Approve Deployment

The workflow will pause at the approval step:

1. The designated reviewer will receive a notification
2. Reviewer goes to the workflow run page
3. Click **Review deployments**
4. Select **production** environment
5. Add optional comment
6. Click **Approve and deploy**

**Timeout**: If not approved within 24 hours, the deployment will be cancelled automatically.

### Step 4: Monitor Deployment

After approval, the workflow will:

1. ✅ Record the approver and timestamp
2. ✅ Backup current production version
3. ✅ Update production Kubernetes manifests
4. ✅ Commit changes to Git
5. ✅ Wait for ArgoCD to sync (5 minutes)
6. ✅ Verify health checks
7. ✅ Send success notification

**OR** if health checks fail:

1. ❌ Automatically rollback to previous version
2. ❌ Commit rollback changes
3. ❌ Send failure notification with details

### Step 5: Verify Deployment

After successful deployment:

1. Check the workflow summary for deployment details
2. Verify ArgoCD shows the application as synced and healthy
3. Test the production application manually
4. Monitor logs and metrics

## Workflow Jobs Explained

### 1. Manual Approval (Required)

- **Purpose**: Gate deployment with human review
- **Timeout**: 24 hours
- **Records**: Approver name and timestamp
- **Requirements**: Designated reviewer must approve

### 2. Backup Current State

- **Purpose**: Save current production version for rollback
- **Records**: Current image tag
- **Use**: Automatic rollback if deployment fails

### 3. Update Manifests

- **Purpose**: Update production Kubernetes manifests with new image
- **Actions**:
  - Updates `k8s/overlays/production/kustomization.yaml`
  - Sets new image tag
  - Commits changes with full deployment details
  - Pushes to main branch

### 4. Wait for ArgoCD

- **Purpose**: Allow time for ArgoCD to detect and sync changes
- **Duration**: 5 minutes (3 min for detection + 2 min for sync)
- **Why needed**: ArgoCD polls Git every 3 minutes by default

### 5. Verify Deployment

- **Purpose**: Ensure production is healthy after deployment
- **Actions**:
  - Runs health check against production endpoint
  - Retries up to 10 times with 30-second delays
  - Fails if health checks don't pass

**Note**: The health check is currently a placeholder. Update the workflow file to configure your actual production URL:

```yaml
PRODUCTION_URL="https://production.yourdomain.com"
```

### 6. Rollback on Failure

- **Purpose**: Automatically revert to previous version if deployment fails
- **Triggers**: Health check failures
- **Actions**:
  - Restores previous image tag
  - Commits rollback changes
  - Pushes to trigger ArgoCD sync
  - Sends failure notification

### 7. Notify Success/Failure

- **Purpose**: Provide deployment summary and status
- **Includes**:
  - Deployment status (success/failure)
  - Image tags (new and previous)
  - Approver information
  - Timestamps
  - Next steps or action items

## Deployment Summary

After each deployment, the workflow creates a comprehensive summary showing:

### Success Summary

```
🚀 Production Deployment Successful

Deployment Details
Status: ✅ Successfully Deployed
Environment: Production
Image: ghcr.io/user/repo:a1b2c3d4...
Previous Version: ghcr.io/user/repo:x9y8z7w6...

Approval Information
Approved by: @username
Approval time: 2024-01-15 10:30:00 UTC
Reason: Deploy new feature

Deployment Timeline
Completed at: 2024-01-15 10:45:00 UTC

Next Steps
- Monitor application metrics and logs
- Verify user-facing functionality
- Check ArgoCD UI for sync status
```

### Failure Summary

```
❌ Production Deployment Failed

Deployment Details
Status: ❌ Failed
Environment: Production
Attempted Image: ghcr.io/user/repo:a1b2c3d4...
Current Version: ghcr.io/user/repo:x9y8z7w6... (rolled back)

Failure Information
Failed at: 2024-01-15 10:45:00 UTC
Approved by: @username

Rollback Status
Automatic rollback was executed successfully

Action Required
1. Review the workflow logs to identify the failure cause
2. Check application logs and ArgoCD sync status
3. Verify the Docker image exists and is accessible
4. Fix the issues before attempting another deployment
5. Consider testing in staging environment first
```

## Rollback Procedure

### Automatic Rollback

The workflow automatically rolls back if:
- Health checks fail after deployment
- ArgoCD sync fails
- Any deployment step fails

No manual intervention needed - the previous version is restored automatically.

### Manual Rollback

If you need to rollback after a successful deployment:

#### Option 1: Via GitHub Actions (Recommended)

1. Go to Actions → CD - Production Deployment
2. Click "Run workflow"
3. Enter the previous image tag (from backup information)
4. Enter reason: "Rollback to previous version"
5. Approve and deploy

#### Option 2: Via kubectl

```bash
# Rollback to previous deployment
kubectl rollout undo deployment/production-nodejs-app -n production

# Rollback to specific revision
kubectl rollout undo deployment/production-nodejs-app -n production --to-revision=2

# Check rollback status
kubectl rollout status deployment/production-nodejs-app -n production
```

#### Option 3: Via ArgoCD

```bash
# Rollback via ArgoCD CLI
argocd app rollback nodejs-app-production

# Or use ArgoCD UI
# 1. Open ArgoCD UI
# 2. Select production application
# 3. Click "History and Rollback"
# 4. Select previous version
# 5. Click "Rollback"
```

#### Option 4: Via Git

```bash
# Revert the manifest change
git revert <commit-sha-of-deployment>
git push origin main

# ArgoCD will automatically sync the revert
```

## Troubleshooting

### Deployment Not Starting

**Problem**: Workflow doesn't start after clicking "Run workflow"

**Solutions**:
1. Verify workflow file exists at `.github/workflows/cd-production.yml`
2. Check YAML syntax is valid
3. Ensure you have write access to the repository
4. Check GitHub Actions is enabled in repository settings

### Approval Not Working

**Problem**: Can't approve deployment or approval button not showing

**Solutions**:
1. Verify production environment is configured in Settings → Environments
2. Check you're added as a required reviewer
3. Ensure environment name is exactly "production" (case-sensitive)
4. Try refreshing the page
5. Check you have appropriate repository permissions

### Health Check Failing

**Problem**: Deployment fails at health check verification

**Solutions**:
1. Verify production URL is accessible
2. Check application logs: `kubectl logs -n production deployment/production-nodejs-app`
3. Verify ArgoCD synced successfully
4. Check pod status: `kubectl get pods -n production`
5. Test health endpoint manually: `curl https://production.yourdomain.com/health`
6. Increase health check timeout or retry count in workflow

### Rollback Not Working

**Problem**: Automatic rollback fails or doesn't trigger

**Solutions**:
1. Check rollback job logs in workflow run
2. Verify backup-current-state job captured previous version
3. Manually rollback using kubectl or ArgoCD
4. Check Git permissions for workflow to push changes
5. Verify ArgoCD is monitoring the repository

### ArgoCD Not Syncing

**Problem**: Manifests updated but ArgoCD doesn't deploy

**Solutions**:
1. Check ArgoCD application status: `argocd app get nodejs-app-production`
2. Verify ArgoCD is monitoring correct Git repository and path
3. Check ArgoCD sync policy is configured correctly
4. Manually trigger sync: `argocd app sync nodejs-app-production`
5. Check ArgoCD logs for errors
6. Verify Git credentials are valid in ArgoCD

### Image Not Found

**Problem**: Deployment fails with "image not found" error

**Solutions**:
1. Verify image exists in GHCR: Check Packages in GitHub
2. Check image tag is correct (full commit SHA)
3. Verify image pull secrets are configured in Kubernetes
4. Test pulling image manually: `docker pull ghcr.io/user/repo:tag`
5. Check GHCR authentication in Kubernetes namespace

## Best Practices

### Before Deploying

1. ✅ **Test thoroughly in staging**: Ensure all features work correctly
2. ✅ **Review changes**: Know what's being deployed
3. ✅ **Check dependencies**: Verify all required services are available
4. ✅ **Plan timing**: Deploy during low-traffic periods if possible
5. ✅ **Notify team**: Let team members know deployment is happening
6. ✅ **Have rollback plan**: Know how to rollback if needed

### During Deployment

1. ✅ **Monitor closely**: Watch workflow progress and logs
2. ✅ **Check ArgoCD**: Verify sync status in ArgoCD UI
3. ✅ **Test immediately**: Verify critical functionality after deployment
4. ✅ **Watch metrics**: Monitor error rates, response times, etc.
5. ✅ **Be ready to rollback**: Have rollback command ready if needed

### After Deployment

1. ✅ **Verify functionality**: Test all critical user flows
2. ✅ **Monitor logs**: Check for errors or warnings
3. ✅ **Check metrics**: Ensure performance is normal
4. ✅ **Update documentation**: Document any changes or issues
5. ✅ **Communicate status**: Let team know deployment is complete

### Deployment Timing

**Recommended times**:
- During business hours (for immediate issue response)
- Low-traffic periods (to minimize user impact)
- When team is available (for quick rollback if needed)

**Avoid**:
- Late Friday deployments (limited support over weekend)
- During high-traffic events
- When key team members are unavailable

## Security Considerations

### Approval Requirements

- Only trusted team members should be designated reviewers
- Require at least 2 reviewers for critical production changes
- Review deployment reason and changes before approving
- Never approve deployments you don't understand

### Image Verification

- Only deploy images from successful staging deployments
- Verify image tag matches expected commit SHA
- Check image was built from correct branch (main)
- Ensure image passed all CI tests

### Access Control

- Limit who can trigger production deployments
- Use GitHub branch protection on main branch
- Require pull request reviews before merging
- Enable audit logging for deployment actions

## Compliance

This production deployment workflow satisfies the following requirements:

- **6.1**: Manual approval required before production deployment ✅
- **6.2**: Deployment proceeds only after approval granted ✅
- **6.3**: Deployment halts if approval denied ✅
- **6.4**: Records approver and timestamp ✅
- **6.5**: 24-hour timeout for approval ✅
- **7.1**: Rolling update strategy for zero downtime ✅
- **7.2**: Backup of current deployment before changes ✅
- **7.3**: Health check verification after deployment ✅
- **7.4**: Automatic rollback on health check failure ✅
- **7.5**: Notifications with failure details ✅

## Related Documentation

- [GitHub Actions CI/CD](github-actions.md)
- [Kubernetes & ArgoCD Setup](kubernetes-argocd-setup.md)
- [Quick Start Guide](QUICK-START-K8S.md)
- [Troubleshooting](../README.md#troubleshooting)

## Example Deployment Session

Here's a complete example of a production deployment:

```bash
# 1. Verify staging is working
curl https://staging.yourdomain.com/health
# Response: {"status":"ok","version":"1.2.0",...}

# 2. Get commit SHA from staging deployment
# From GitHub Actions: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0

# 3. Trigger production deployment
# Go to Actions → CD - Production Deployment → Run workflow
# Image tag: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0
# Reason: Deploy user authentication feature v1.2.0

# 4. Approve deployment
# Reviewer receives notification → Reviews changes → Approves

# 5. Monitor deployment
# Watch workflow progress in GitHub Actions
# Check ArgoCD: argocd app get nodejs-app-production

# 6. Verify production
curl https://production.yourdomain.com/health
# Response: {"status":"ok","version":"1.2.0",...}

# 7. Test critical functionality
curl https://production.yourdomain.com/api/users
# Verify response is correct

# 8. Monitor for issues
kubectl logs -f -n production deployment/production-nodejs-app

# ✅ Deployment successful!
```

## Support

If you encounter issues not covered in this guide:

1. Check workflow logs in GitHub Actions
2. Review ArgoCD application status
3. Check Kubernetes pod logs
4. Consult team members or documentation
5. Create an issue in the repository with details
