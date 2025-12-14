# Quick Reference Card

## Current Setup Status

```
✅ Code & Config: Complete
✅ Staging: Deployed & Running
⏳ Production: Ready (not deployed)
⏳ GitHub Envs: Not created yet
```

## What You Have Now

### Working
- Staging environment in Kubernetes with ArgoCD
- Environment-specific configuration (dev, staging, production)
- CI/CD pipelines (GitHub Actions)
- All tests passing

### Ready But Not Deployed
- Production Kubernetes manifests
- Production ArgoCD application definition
- Production approval workflow (needs GitHub environment)

## Quick Commands

### Check Staging
```bash
# ArgoCD status
argocd app get nodejs-app-staging

# Pods
kubectl get pods -n staging

# Logs
kubectl logs -f deployment/staging-nodejs-app -n staging

# Test app
kubectl port-forward -n staging svc/staging-nodejs-app 8080:80
curl http://localhost:8080/health
```

### Deploy Production (When Ready)
```bash
# 1. Create namespace
kubectl create namespace production

# 2. Create secrets (replace with real values)
kubectl create secret generic nodejs-app-secrets \
  --from-literal=API_KEY='prod-key' \
  --namespace=production

# 3. Create image pull secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_TOKEN \
  --namespace=production

# 4. Deploy ArgoCD app
kubectl apply -f k8s/argocd/production-app.yaml

# 5. Sync
argocd app sync nodejs-app-production
```

### Create GitHub Environments
1. Go to: Settings → Environments
2. Create `staging` (no rules)
3. Create `production` (add reviewers)

## Configuration Differences

| Setting | Staging | Production |
|---------|---------|------------|
| NODE_ENV | staging | production |
| LOG_LEVEL | info | warn |
| LOG_FORMAT | text | **json** |
| Detailed Errors | true | **false** |
| Replicas | 2 | 3 |
| Sync | Auto | Manual |

## Important Files

### Configuration
- `.env.example` - Environment variables template
- `src/config/index.js` - Configuration loader
- `k8s/base/configmap.yaml` - Base config
- `k8s/overlays/*/kustomization.yaml` - Environment overrides

### Secrets
- `k8s/base/secret.yaml` - Secret template (not used directly)
- `k8s/SECRETS-MANAGEMENT.md` - How to create secrets

### Documentation
- `DEPLOYMENT-STATUS.md` - Current status
- `docs/environment-configuration.md` - Config guide
- `docs/github-environments-setup.md` - GitHub setup
- `docs/deploy-production-argocd.md` - Production deployment

## Test Configuration

```bash
# Run all tests
npm test

# Run specific tests
npm test -- tests/config.test.js
npm test -- tests/errorHandler.test.js

# Verify configuration
node verify-config.js
```

## Troubleshooting

### Staging not syncing
```bash
argocd app sync nodejs-app-staging --force
```

### Check configuration
```bash
kubectl get configmap staging-nodejs-app-config -n staging -o yaml
```

### View secrets (base64 encoded)
```bash
kubectl get secret nodejs-app-secrets -n staging -o yaml
```

### Restart deployment
```bash
kubectl rollout restart deployment/staging-nodejs-app -n staging
```

## What's Next?

### Optional Now
- [ ] Create GitHub environments for approval workflow
- [ ] Add secrets to staging (app works without them)

### When Ready
- [ ] Deploy production following guide
- [ ] Test production approval workflow
- [ ] Set up monitoring

## Need Help?

- **Environment Config**: `docs/environment-configuration.md`
- **Secrets**: `k8s/SECRETS-MANAGEMENT.md`
- **GitHub Setup**: `docs/github-environments-setup.md`
- **Production Deploy**: `docs/deploy-production-argocd.md`
- **Status**: `DEPLOYMENT-STATUS.md`
