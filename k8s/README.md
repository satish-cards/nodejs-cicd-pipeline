# Kubernetes Manifests

This directory contains all Kubernetes manifests for deploying the Node.js CI/CD Pipeline application.

## Directory Structure

```
k8s/
├── base/                    # Base Kubernetes resources
│   ├── deployment.yaml      # Application deployment
│   ├── service.yaml         # Service definition
│   ├── configmap.yaml       # Non-sensitive configuration
│   ├── secret.yaml          # Secret template (not used directly)
│   └── kustomization.yaml   # Base kustomization
├── overlays/                # Environment-specific overlays
│   ├── staging/             # Staging environment
│   │   ├── kustomization.yaml
│   │   └── patches.yaml
│   └── production/          # Production environment
│       ├── kustomization.yaml
│       └── patches.yaml
├── argocd/                  # ArgoCD application definitions
│   ├── staging-app.yaml     # Staging ArgoCD app
│   └── production-app.yaml  # Production ArgoCD app
├── SECRETS-MANAGEMENT.md    # Secrets management guide
└── README.md                # This file
```

## Quick Start

### Deploy to Staging

```bash
kubectl apply -k k8s/overlays/staging
```

### Deploy to Production

```bash
kubectl apply -k k8s/overlays/production
```

## Configuration Management

### Non-Sensitive Configuration (ConfigMaps)

ConfigMaps are managed through Kustomize and stored in Git:

- **Base ConfigMap**: `k8s/base/configmap.yaml`
- **Staging Override**: `k8s/overlays/staging/kustomization.yaml`
- **Production Override**: `k8s/overlays/production/kustomization.yaml`

To update configuration:
1. Edit the appropriate kustomization file
2. Commit and push changes
3. ArgoCD will automatically sync (or apply manually)
4. Restart pods to pick up changes

### Sensitive Configuration (Secrets)

Secrets are NOT stored in Git. See [SECRETS-MANAGEMENT.md](./SECRETS-MANAGEMENT.md) for detailed instructions.

Quick reference:
```bash
# Create secret
kubectl create secret generic nodejs-app-secrets \
  --from-literal=API_KEY='your-key' \
  --namespace=staging

# View secrets
kubectl get secrets -n staging

# Update secret
kubectl create secret generic nodejs-app-secrets \
  --from-literal=API_KEY='new-key' \
  --namespace=staging \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Environment-Specific Settings

### Staging
- **Namespace**: `staging`
- **Replicas**: 2
- **NODE_ENV**: staging
- **LOG_LEVEL**: info
- **Sync**: Automatic via ArgoCD
- **Purpose**: Pre-production testing

### Production
- **Namespace**: `production`
- **Replicas**: 3
- **NODE_ENV**: production
- **LOG_LEVEL**: warn
- **Sync**: Manual approval required
- **Purpose**: Live production workload

## Using Kustomize

### Preview Changes

```bash
# Preview staging manifests
kubectl kustomize k8s/overlays/staging

# Preview production manifests
kubectl kustomize k8s/overlays/production
```

### Apply Changes

```bash
# Apply staging
kubectl apply -k k8s/overlays/staging

# Apply production
kubectl apply -k k8s/overlays/production
```

### Validate Manifests

```bash
# Dry-run to validate
kubectl apply -k k8s/overlays/staging --dry-run=client

# Use kubeval (if installed)
kubectl kustomize k8s/overlays/staging | kubeval
```

## ArgoCD GitOps

### Install ArgoCD Applications

```bash
# Install staging app
kubectl apply -f k8s/argocd/staging-app.yaml

# Install production app
kubectl apply -f k8s/argocd/production-app.yaml
```

### Sync Applications

```bash
# Sync staging (automatic by default)
argocd app sync nodejs-app-staging

# Sync production (manual approval required)
argocd app sync nodejs-app-production
```

### View Application Status

```bash
# List applications
argocd app list

# Get application details
argocd app get nodejs-app-staging

# View sync history
argocd app history nodejs-app-staging
```

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -n staging

# View pod logs
kubectl logs -f deployment/staging-nodejs-app -n staging

# Describe pod for events
kubectl describe pod <pod-name> -n staging
```

### ConfigMap not updating

```bash
# Verify ConfigMap
kubectl get configmap nodejs-app-config -n staging -o yaml

# Restart deployment to pick up changes
kubectl rollout restart deployment/staging-nodejs-app -n staging
```

### Secret issues

See [SECRETS-MANAGEMENT.md](./SECRETS-MANAGEMENT.md) for detailed troubleshooting.

### ArgoCD sync issues

```bash
# Check sync status
argocd app get nodejs-app-staging

# Force sync
argocd app sync nodejs-app-staging --force

# View sync logs
kubectl logs -n argocd deployment/argocd-application-controller
```

## Best Practices

1. **Always test in staging first** - Validate changes before production
2. **Use Kustomize overlays** - Keep environment-specific config separate
3. **Never commit secrets** - Use proper secrets management
4. **Version your changes** - Commit manifest updates with descriptive messages
5. **Monitor deployments** - Watch ArgoCD and pod status during rollouts
6. **Use health checks** - Ensure liveness and readiness probes are configured
7. **Set resource limits** - Prevent resource exhaustion
8. **Enable RBAC** - Limit access to sensitive resources

## Additional Resources

- [Environment Configuration Guide](../docs/environment-configuration.md)
- [Secrets Management Guide](./SECRETS-MANAGEMENT.md)
- [ArgoCD Setup Guide](../docs/kubernetes-argocd-setup.md)
- [Kubernetes Quick Start](../docs/QUICK-START-K8S.md)
