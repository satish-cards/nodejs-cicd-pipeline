# ArgoCD Application Manifests

This directory contains ArgoCD Application manifests for deploying the Node.js CI/CD pipeline application to different environments.

## Prerequisites

1. ArgoCD must be installed in your Kubernetes cluster
2. ArgoCD CLI installed locally (optional, for command-line operations)
3. Access to the Kubernetes cluster with appropriate permissions

## Files

- `staging-app.yaml` - ArgoCD Application for staging environment
- `production-app.yaml` - ArgoCD Application for production environment

## Configuration

Before applying these manifests, you need to update the following placeholders:

1. **Repository URL**: Replace `GITHUB_USERNAME/REPO_NAME` with your actual GitHub repository
   - In `staging-app.yaml`: Line with `repoURL`
   - In `production-app.yaml`: Line with `repoURL`

Example:
```yaml
repoURL: https://github.com/yourusername/nodejs-cicd-pipeline
```

## Deployment

### Installing ArgoCD

If ArgoCD is not already installed in your cluster:

```bash
# Create argocd namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access ArgoCD UI at: https://localhost:8080
- Username: `admin`
- Password: (from the command above)

### Applying Application Manifests

After updating the repository URLs:

```bash
# Apply staging application
kubectl apply -f k8s/argocd/staging-app.yaml

# Apply production application
kubectl apply -f k8s/argocd/production-app.yaml
```

### Verifying Applications

```bash
# Check application status
kubectl get applications -n argocd

# Get detailed status
kubectl describe application nodejs-app-staging -n argocd
kubectl describe application nodejs-app-production -n argocd
```

Using ArgoCD CLI:

```bash
# Login to ArgoCD
argocd login localhost:8080

# List applications
argocd app list

# Get application details
argocd app get nodejs-app-staging
argocd app get nodejs-app-production
```

## Sync Policies

### Staging Environment

**Automated Sync**: Enabled
- Automatically syncs when changes are detected in Git
- **Prune**: Enabled - removes resources not defined in Git
- **Self-Heal**: Enabled - reverts manual changes to match Git state
- **Namespace**: `staging`

The staging application will automatically deploy whenever:
- Changes are pushed to the `main` branch
- Kubernetes manifests in `k8s/overlays/staging/` are updated
- The CD pipeline updates the image tag

### Production Environment

**Manual Sync**: Required
- Requires manual approval before syncing
- **Prune**: Available when manually synced
- **Self-Heal**: Available when manually synced
- **Namespace**: `production`

To deploy to production:

```bash
# Using ArgoCD UI
# 1. Navigate to the nodejs-app-production application
# 2. Click "Sync" button
# 3. Review changes
# 4. Click "Synchronize"

# Using ArgoCD CLI
argocd app sync nodejs-app-production

# Sync with prune and self-heal
argocd app sync nodejs-app-production --prune --self-heal
```

## Monitoring

### ArgoCD UI

Access the ArgoCD UI to monitor:
- Application health status
- Sync status and history
- Resource tree view
- Deployment events and logs

### CLI Monitoring

```bash
# Watch application status
argocd app watch nodejs-app-staging

# Get sync status
argocd app get nodejs-app-staging --refresh

# View application history
argocd app history nodejs-app-staging
```

### Kubernetes Monitoring

```bash
# Check staging deployment
kubectl get all -n staging

# Check production deployment
kubectl get all -n production

# View application logs
kubectl logs -n staging -l app=nodejs-app --tail=100 -f
kubectl logs -n production -l app=nodejs-app --tail=100 -f
```

## Rollback

### Using ArgoCD

```bash
# List application history
argocd app history nodejs-app-production

# Rollback to previous version
argocd app rollback nodejs-app-production

# Rollback to specific revision
argocd app rollback nodejs-app-production <revision-id>
```

### Using Git

Since this is GitOps, you can also rollback by reverting Git commits:

```bash
# Revert the last commit
git revert HEAD
git push origin main

# ArgoCD will automatically sync staging
# Production will require manual sync
```

## Troubleshooting

### Application Not Syncing

```bash
# Check application status
argocd app get nodejs-app-staging

# Force refresh
argocd app get nodejs-app-staging --refresh --hard-refresh

# Check sync errors
kubectl describe application nodejs-app-staging -n argocd
```

### Sync Failures

```bash
# View detailed sync status
argocd app get nodejs-app-staging --show-operation

# Check application events
kubectl get events -n staging --sort-by='.lastTimestamp'
```

### Health Check Failures

```bash
# Check pod status
kubectl get pods -n staging
kubectl describe pod <pod-name> -n staging

# Check application logs
kubectl logs -n staging -l app=nodejs-app --tail=100
```

## Best Practices

1. **Always test in staging first** - Let staging auto-sync and verify before production
2. **Review changes before production sync** - Use ArgoCD UI to review diff before syncing production
3. **Use Git for all changes** - Never make manual changes to production resources
4. **Monitor sync status** - Set up alerts for sync failures
5. **Keep revision history** - The `revisionHistoryLimit: 10` keeps last 10 revisions for rollback

## Security Considerations

1. **Repository Access**: Ensure ArgoCD has read-only access to your Git repository
2. **RBAC**: Configure appropriate RBAC policies for ArgoCD users
3. **Secrets**: Use Sealed Secrets or external secret management for sensitive data
4. **Network Policies**: Implement network policies to restrict traffic between namespaces

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [GitOps Principles](https://opengitops.dev/)
