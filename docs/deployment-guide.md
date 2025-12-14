# Deployment Guide

This guide provides step-by-step instructions for deploying the Node.js application to staging and production environments using the CI/CD pipeline.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Deployment Overview](#deployment-overview)
3. [Deploying to Staging](#deploying-to-staging)
4. [Deploying to Production](#deploying-to-production)
5. [Verifying Deployments](#verifying-deployments)
6. [Rolling Back Deployments](#rolling-back-deployments)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

Before deploying, ensure you have:

- ✅ GitHub repository with code pushed
- ✅ GitHub Actions workflows configured
- ✅ GitHub Container Registry (GHCR) access
- ✅ Kubernetes cluster running (Minikube or cloud)
- ✅ ArgoCD installed and configured
- ✅ kubectl configured to access cluster
- ✅ Image pull secrets created in namespaces

If you haven't set these up yet, see:
- [Git and GitHub Setup](git-github-setup.md)
- [Kubernetes and ArgoCD Setup](kubernetes-argocd-setup.md)
- [GitHub Actions Documentation](github-actions.md)

## Deployment Overview

### Deployment Flow

```
Code Push → CI Pipeline → Staging (Auto) → Production (Manual)
```

### Environments

| Environment | Trigger | Approval | Replicas | Sync Policy |
|-------------|---------|----------|----------|-------------|
| Staging | Automatic (main branch) | None | 2 | Auto-sync |
| Production | Manual | Required | 3 | Manual sync |

### Deployment Strategy

Both environments use **rolling updates** for zero-downtime deployments:
- New pods are created before old ones are terminated
- Health checks ensure new pods are ready before traffic is routed
- Old pods are terminated only after new pods are healthy

## Deploying to Staging

Staging deployments happen automatically when code is merged to the main branch.

### Step 1: Merge Code to Main Branch

**Option A: Via Pull Request (Recommended)**

1. Create a feature branch:
   ```bash
   git checkout -b feature/my-feature
   ```

2. Make changes and commit:
   ```bash
   git add .
   git commit -m "Add new feature"
   git push origin feature/my-feature
   ```

3. Create Pull Request on GitHub:
   - Go to your repository on GitHub
   - Click "Pull requests" → "New pull request"
   - Select your feature branch
   - Click "Create pull request"
   - Add description and reviewers

4. Wait for CI to pass:
   - CI workflow runs automatically
   - All checks must pass (lint, test, build)
   - Review and approve the PR

5. Merge the Pull Request:
   - Click "Merge pull request"
   - Confirm merge
   - Delete feature branch (optional)

**Option B: Direct Push (Not Recommended)**

```bash
git checkout main
git pull origin main
git merge feature/my-feature
git push origin main
```

### Step 2: Monitor CI Pipeline

1. Go to GitHub Actions tab in your repository
2. Find the "CI Pipeline" workflow run
3. Watch the progress:
   - ✅ Install Dependencies
   - ✅ Lint Code
   - ✅ Run Tests
   - ✅ Build Docker Image
   - ✅ Push to GHCR

**Expected Duration**: ~2 minutes

### Step 3: Monitor CD Staging Pipeline

After CI completes, the CD Staging workflow automatically triggers:

1. Go to GitHub Actions tab
2. Find the "CD - Staging Deployment" workflow run
3. Watch the progress:
   - ✅ Build and push image
   - ✅ Update staging manifests
   - ✅ Commit changes
   - ✅ Verify health check

**Expected Duration**: ~3-5 minutes

### Step 4: Monitor ArgoCD Sync

ArgoCD automatically detects the manifest changes and syncs:

1. Open ArgoCD UI:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Then open: https://localhost:8080

2. Login with admin credentials

3. Find "nodejs-app-staging" application

4. Watch the sync progress:
   - Status changes to "Syncing"
   - Kubernetes resources are updated
   - Health checks run
   - Status changes to "Healthy" and "Synced"

**Expected Duration**: ~1-2 minutes

### Step 5: Verify Staging Deployment

Check that the application is running:

```bash
# Check pod status
kubectl get pods -n staging

# Expected output:
# NAME                                   READY   STATUS    RESTARTS   AGE
# staging-nodejs-app-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
# staging-nodejs-app-xxxxxxxxxx-xxxxx    1/1     Running   0          2m

# Check deployment
kubectl get deployment staging-nodejs-app -n staging

# Check service
kubectl get service staging-nodejs-app -n staging
```

Test the application:

```bash
# Option 1: Port forward
kubectl port-forward svc/staging-nodejs-app -n staging 3000:3000

# Then test:
curl http://localhost:3000/health
curl http://localhost:3000/api/users
curl http://localhost:3000/api/data

# Option 2: Minikube service (if using Minikube)
minikube service staging-nodejs-app -n staging --url

# Then test with the returned URL:
curl $(minikube service staging-nodejs-app -n staging --url)/health
```

**Expected Response**:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "version": "1.0.0",
  "uptime": 120,
  "environment": "staging"
}
```

### Staging Deployment Complete! ✅

Your application is now running in staging. Proceed to production deployment when ready.

## Deploying to Production

Production deployments require manual approval and are triggered manually.

### Step 1: Verify Staging is Healthy

Before deploying to production, ensure staging is working correctly:

```bash
# Check staging health
curl $(kubectl get svc staging-nodejs-app -n staging -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/health

# Or with port-forward:
kubectl port-forward svc/staging-nodejs-app -n staging 3000:3000
curl http://localhost:3000/health
```

Perform manual testing:
- ✅ Test all API endpoints
- ✅ Check logs for errors
- ✅ Verify metrics are being collected
- ✅ Test error scenarios

### Step 2: Trigger Production Deployment

1. Go to GitHub repository → Actions tab

2. Select "CD - Production Deployment" workflow

3. Click "Run workflow" button

4. Fill in the parameters:
   - **Branch**: main (default)
   - **Image Tag**: Enter the commit SHA from staging
     - Find it in the staging deployment or GitHub Actions logs
     - Example: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0`
   - **Deployment Reason**: Brief description
     - Example: "Deploy feature X to production"

5. Click "Run workflow"

### Step 3: Approve Production Deployment

The workflow will pause and wait for approval:

1. Go to the running workflow

2. You'll see "Waiting for approval" status

3. Click "Review deployments"

4. Select "production" environment

5. Add approval comment (optional)

6. Click "Approve and deploy"

**Approval Timeout**: 24 hours (deployment will be cancelled if not approved)

**Who Can Approve**: Users configured in GitHub Environment protection rules

### Step 4: Monitor Production Deployment

After approval, the workflow continues:

1. Watch the workflow progress:
   - ✅ Backup current state
   - ✅ Update production manifests
   - ✅ Commit changes
   - ✅ Wait for ArgoCD sync
   - ✅ Verify health checks
   - ✅ Notify success/failure

2. Monitor ArgoCD:
   - Open ArgoCD UI
   - Find "nodejs-app-production" application
   - Watch sync progress

3. Monitor Kubernetes:
   ```bash
   # Watch pods rolling update
   kubectl get pods -n production -w
   
   # Check deployment status
   kubectl rollout status deployment/production-nodejs-app -n production
   ```

**Expected Duration**: ~5-10 minutes

### Step 5: Verify Production Deployment

Check that the application is running:

```bash
# Check pod status
kubectl get pods -n production

# Expected output:
# NAME                                      READY   STATUS    RESTARTS   AGE
# production-nodejs-app-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
# production-nodejs-app-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
# production-nodejs-app-xxxxxxxxxx-xxxxx    1/1     Running   0          2m

# Check deployment
kubectl get deployment production-nodejs-app -n production
```

Test the application:

```bash
# Port forward
kubectl port-forward svc/production-nodejs-app -n production 3000:3000

# Test endpoints
curl http://localhost:3000/health
curl http://localhost:3000/api/users
curl http://localhost:3000/api/data
```

Check logs for errors:

```bash
# View logs from all pods
kubectl logs -f deployment/production-nodejs-app -n production

# View logs from specific pod
kubectl logs <pod-name> -n production
```

### Production Deployment Complete! ✅

Your application is now running in production.

## Verifying Deployments

### Health Checks

All deployments include automatic health checks:

```bash
# Staging
curl http://<staging-url>/health

# Production
curl http://<production-url>/health
```

**Expected Response**:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "version": "1.0.0",
  "uptime": 120,
  "environment": "production"
}
```

### Kubernetes Health

Check Kubernetes resources:

```bash
# Check all resources
kubectl get all -n production

# Check pod health
kubectl get pods -n production

# Check deployment status
kubectl get deployment production-nodejs-app -n production

# Check service
kubectl get service production-nodejs-app -n production
```

### ArgoCD Health

Check ArgoCD application status:

```bash
# Via ArgoCD CLI
argocd app get nodejs-app-production

# Expected output:
# Health Status:      Healthy
# Sync Status:        Synced
```

Or via ArgoCD UI:
- Open https://localhost:8080
- Find application
- Check status indicators (should be green)

### Application Logs

Monitor application logs:

```bash
# Tail logs
kubectl logs -f deployment/production-nodejs-app -n production

# Get recent logs
kubectl logs --tail=100 deployment/production-nodejs-app -n production

# Get logs from all pods
kubectl logs -l app=production-nodejs-app -n production
```

### Metrics

Check application metrics:

```bash
# Port forward to metrics endpoint
kubectl port-forward svc/production-nodejs-app -n production 3000:3000

# Get metrics
curl http://localhost:3000/metrics
```

## Rolling Back Deployments

If issues are discovered after deployment, you can rollback quickly.

### Automatic Rollback

Production deployments automatically rollback if:
- Health checks fail after deployment
- Pods fail to start
- Application crashes repeatedly

The CD workflow detects failures and reverts to the previous version automatically.

### Manual Rollback

#### Method 1: Via Git (Recommended)

Revert the deployment commit:

```bash
# Find the deployment commit
git log --oneline

# Revert the commit
git revert <commit-sha>

# Push the revert
git push origin main
```

ArgoCD will automatically sync the previous version.

#### Method 2: Via ArgoCD UI

1. Open ArgoCD UI: https://localhost:8080
2. Select the application (staging or production)
3. Click "History and Rollback" tab
4. Find the previous successful deployment
5. Click "Rollback" button
6. Confirm rollback

#### Method 3: Via ArgoCD CLI

```bash
# Rollback to previous version
argocd app rollback nodejs-app-production

# Rollback to specific revision
argocd app rollback nodejs-app-production <revision-number>
```

#### Method 4: Via kubectl

```bash
# Rollback deployment
kubectl rollout undo deployment/production-nodejs-app -n production

# Rollback to specific revision
kubectl rollout undo deployment/production-nodejs-app -n production --to-revision=2

# Check rollback status
kubectl rollout status deployment/production-nodejs-app -n production
```

### Verify Rollback

After rollback, verify the application:

```bash
# Check pods are running
kubectl get pods -n production

# Check deployment revision
kubectl rollout history deployment/production-nodejs-app -n production

# Test health endpoint
curl http://<production-url>/health

# Check logs
kubectl logs -f deployment/production-nodejs-app -n production
```

## Troubleshooting

### Deployment Stuck in "Progressing"

**Symptom**: Deployment shows "Progressing" for extended time

**Possible Causes**:
- Image pull errors
- Insufficient resources
- Health check failures
- Configuration errors

**Solution**:

```bash
# Check deployment status
kubectl describe deployment production-nodejs-app -n production

# Check pod status
kubectl get pods -n production
kubectl describe pod <pod-name> -n production

# Check events
kubectl get events -n production --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name> -n production
```

### Image Pull Errors

**Symptom**: Pods show "ImagePullBackOff" or "ErrImagePull"

**Possible Causes**:
- Image doesn't exist in GHCR
- Image pull secret missing or invalid
- Incorrect image tag

**Solution**:

```bash
# Check if image exists in GHCR
# Go to GitHub → Packages → nodejs-cicd-pipeline

# Verify image pull secret exists
kubectl get secret ghcr-secret -n production

# Recreate image pull secret if needed
kubectl delete secret ghcr-secret -n production
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USERNAME \
  --docker-password=$GITHUB_TOKEN \
  -n production

# Check deployment uses the secret
kubectl get deployment production-nodejs-app -n production -o yaml | grep imagePullSecrets
```

### Health Check Failures

**Symptom**: Pods show "Unhealthy" or restart frequently

**Possible Causes**:
- Application not starting correctly
- Health endpoint not responding
- Configuration errors
- Resource constraints

**Solution**:

```bash
# Check pod logs
kubectl logs <pod-name> -n production

# Check pod events
kubectl describe pod <pod-name> -n production

# Check health endpoint manually
kubectl port-forward <pod-name> -n production 3000:3000
curl http://localhost:3000/health

# Check resource usage
kubectl top pod <pod-name> -n production
```

### ArgoCD Out of Sync

**Symptom**: ArgoCD shows "OutOfSync" status

**Possible Causes**:
- Manual changes to cluster
- Manifest errors
- Git repository issues

**Solution**:

```bash
# Check sync status
argocd app get nodejs-app-production

# View differences
argocd app diff nodejs-app-production

# Force sync
argocd app sync nodejs-app-production

# Hard refresh (ignore cache)
argocd app get nodejs-app-production --hard-refresh
```

### Deployment Timeout

**Symptom**: Deployment times out waiting for pods

**Possible Causes**:
- Slow image pull
- Application startup time too long
- Resource constraints

**Solution**:

```bash
# Increase deployment timeout in manifest
# Edit k8s/base/deployment.yaml:
# spec.progressDeadlineSeconds: 600  # 10 minutes

# Check resource availability
kubectl describe nodes

# Check pod resource requests/limits
kubectl describe pod <pod-name> -n production
```

### Configuration Errors

**Symptom**: Application starts but behaves incorrectly

**Possible Causes**:
- Wrong environment variables
- Missing configuration
- Incorrect ConfigMap or Secret

**Solution**:

```bash
# Check ConfigMap
kubectl get configmap -n production
kubectl describe configmap <configmap-name> -n production

# Check environment variables in pod
kubectl exec <pod-name> -n production -- env

# Check application logs for config errors
kubectl logs <pod-name> -n production | grep -i error
```

## Best Practices

### Before Deploying

1. ✅ **Test locally** - Ensure changes work on your machine
2. ✅ **Run full test suite** - All tests must pass
3. ✅ **Review code** - Get peer review on pull requests
4. ✅ **Check CI** - Ensure CI pipeline passes
5. ✅ **Test in staging** - Verify in staging environment first

### During Deployment

1. ✅ **Monitor actively** - Watch logs and metrics during deployment
2. ✅ **Have rollback ready** - Know how to rollback quickly
3. ✅ **Deploy during low traffic** - Minimize user impact
4. ✅ **Communicate** - Notify team of deployment
5. ✅ **Document changes** - Update changelog

### After Deployment

1. ✅ **Verify health** - Check all endpoints work
2. ✅ **Monitor metrics** - Watch for anomalies
3. ✅ **Check logs** - Look for errors or warnings
4. ✅ **Test functionality** - Verify new features work
5. ✅ **Stay available** - Be ready to respond to issues

### General Guidelines

1. **Deploy frequently** - Small, frequent deployments are safer
2. **Automate everything** - Reduce human error
3. **Test thoroughly** - Catch issues before production
4. **Monitor continuously** - Detect issues quickly
5. **Document incidents** - Learn from failures
6. **Practice rollbacks** - Be prepared for emergencies

## Deployment Checklist

Use this checklist for production deployments:

### Pre-Deployment

- [ ] All tests passing in CI
- [ ] Code reviewed and approved
- [ ] Staging deployment successful
- [ ] Manual testing completed in staging
- [ ] No known critical bugs
- [ ] Deployment window scheduled
- [ ] Team notified of deployment
- [ ] Rollback plan documented

### During Deployment

- [ ] Trigger production workflow
- [ ] Obtain required approvals
- [ ] Monitor deployment progress
- [ ] Watch ArgoCD sync status
- [ ] Check pod rollout status
- [ ] Verify health checks pass

### Post-Deployment

- [ ] Test all critical endpoints
- [ ] Check application logs
- [ ] Monitor error rates
- [ ] Verify metrics collection
- [ ] Test new features
- [ ] Update documentation
- [ ] Notify team of completion
- [ ] Monitor for 30 minutes

### If Issues Occur

- [ ] Assess severity
- [ ] Decide: fix forward or rollback
- [ ] Execute rollback if needed
- [ ] Verify rollback successful
- [ ] Document incident
- [ ] Schedule post-mortem

## Related Documentation

- [CI/CD Overview](ci-cd-overview.md) - Pipeline architecture
- [GitHub Actions](github-actions.md) - Workflow details
- [ArgoCD Setup](argocd-setup.md) - ArgoCD configuration
- [Environment Configuration](environment-configuration.md) - Configuration management

## Getting Help

If you encounter issues not covered in this guide:

1. Check application logs: `kubectl logs -f deployment/<name> -n <namespace>`
2. Check Kubernetes events: `kubectl get events -n <namespace>`
3. Check ArgoCD logs: `kubectl logs -f deployment/argocd-server -n argocd`
4. Review GitHub Actions workflow logs
5. Consult the troubleshooting section above
6. Ask your team for help

Remember: When in doubt, rollback first, investigate later. User experience is the priority.
