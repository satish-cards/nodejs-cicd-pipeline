# Deploying Production ArgoCD Application

## Prerequisites

Before deploying the production ArgoCD application:

1. ✅ Staging environment is working correctly
2. ✅ Application has been tested in staging
3. ✅ GitHub production environment is configured (for approval workflow)
4. ✅ Production secrets are created in Kubernetes
5. ✅ Production namespace exists

## Step 1: Create Production Namespace

```bash
kubectl create namespace production
```

## Step 2: Create Production Secrets

```bash
# Create production secrets (replace with actual values)
kubectl create secret generic nodejs-app-secrets \
  --from-literal=API_KEY='your-production-api-key' \
  --from-literal=JWT_SECRET='your-production-jwt-secret' \
  --from-literal=DATABASE_URL='your-production-db-url' \
  --namespace=production

# Verify secret was created
kubectl get secret nodejs-app-secrets -n production
```

## Step 3: Create GHCR Pull Secret for Production

```bash
# Create image pull secret for production namespace
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_TOKEN \
  --namespace=production

# Verify secret was created
kubectl get secret ghcr-secret -n production
```

## Step 4: Deploy ArgoCD Production Application

```bash
# Apply the production ArgoCD application
kubectl apply -f k8s/argocd/production-app.yaml

# Verify application was created
kubectl get application -n argocd nodejs-app-production
```

## Step 5: Verify Deployment

```bash
# Check ArgoCD application status
argocd app get nodejs-app-production

# Check if application is synced
argocd app list | grep production

# View application in ArgoCD UI
# Navigate to: http://localhost:8080 (or your ArgoCD URL)
```

## Step 6: Manual Sync (First Time)

Since production uses manual sync, you need to sync it manually:

```bash
# Sync the application
argocd app sync nodejs-app-production

# Watch the sync progress
argocd app wait nodejs-app-production --health
```

## Step 7: Verify Application is Running

```bash
# Check pods
kubectl get pods -n production

# Check deployment
kubectl get deployment -n production

# Check service
kubectl get service -n production

# Test health endpoint (if using port-forward)
kubectl port-forward -n production svc/production-nodejs-app 8080:80
curl http://localhost:8080/health
```

## Expected Output

After successful deployment, you should see:

```bash
$ kubectl get pods -n production
NAME                                      READY   STATUS    RESTARTS   AGE
production-nodejs-app-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
production-nodejs-app-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
production-nodejs-app-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
```

## Configuration Verification

Verify production configuration is correct:

```bash
# Check ConfigMap
kubectl get configmap production-nodejs-app-config -n production -o yaml

# Should show:
# NODE_ENV: production
# LOG_LEVEL: warn
# ENABLE_DETAILED_ERRORS: "false"
# ENABLE_METRICS: "true"

# Check environment variables in pod
kubectl exec -n production deployment/production-nodejs-app -- env | grep NODE_ENV
# Should output: NODE_ENV=production
```

## Deployment Workflow

After initial setup, deployments work like this:

1. **Code merged to main** → Staging deploys automatically
2. **Test in staging** → Verify everything works
3. **Trigger production workflow** → Manually from GitHub Actions
4. **Approval required** → Designated reviewer approves
5. **Manifest updated** → GitHub Actions updates production kustomization
6. **ArgoCD syncs** → Manual sync in ArgoCD (or configure auto-sync)
7. **Rolling update** → Kubernetes performs rolling update
8. **Health checks** → Verify new pods are healthy

## Rollback Production

If something goes wrong:

```bash
# Option 1: Rollback via kubectl
kubectl rollout undo deployment/production-nodejs-app -n production

# Option 2: Rollback via ArgoCD
argocd app rollback nodejs-app-production

# Option 3: Revert Git commit and sync
git revert <commit-sha>
git push origin main
argocd app sync nodejs-app-production
```

## Monitoring Production

```bash
# Watch pods
kubectl get pods -n production -w

# View logs
kubectl logs -f deployment/production-nodejs-app -n production

# Check events
kubectl get events -n production --sort-by='.lastTimestamp'

# ArgoCD application health
argocd app get nodejs-app-production
```

## Troubleshooting

### Application not syncing
```bash
# Check ArgoCD application status
argocd app get nodejs-app-production

# View sync errors
kubectl describe application nodejs-app-production -n argocd

# Force sync
argocd app sync nodejs-app-production --force
```

### Pods not starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n production

# Common issues:
# - Image pull errors: Check ghcr-secret
# - Secret not found: Create nodejs-app-secrets
# - ConfigMap not found: Check kustomization
```

### Health check failing
```bash
# Check pod logs
kubectl logs deployment/production-nodejs-app -n production

# Test health endpoint
kubectl port-forward -n production svc/production-nodejs-app 8080:80
curl http://localhost:8080/health
```

## Security Checklist

Before going live with production:

- [ ] Production secrets are different from staging
- [ ] ENABLE_DETAILED_ERRORS is set to false
- [ ] LOG_LEVEL is set to warn or error
- [ ] Resource limits are configured
- [ ] RBAC is properly configured
- [ ] Network policies are in place (if applicable)
- [ ] Backup strategy is defined
- [ ] Monitoring and alerting is configured

## Next Steps

After production is deployed:

1. Set up monitoring (Prometheus/Grafana)
2. Configure alerting
3. Set up log aggregation
4. Document runbooks
5. Plan for scaling
6. Regular security updates

## Current Status

Based on your setup:
- ✅ Staging ArgoCD application: Deployed and working
- ⏳ Production ArgoCD application: Ready to deploy (follow steps above)
- ⏳ GitHub production environment: Needs to be created for approval workflow

## Quick Deploy Script

Save this as `deploy-production.sh`:

```bash
#!/bin/bash
set -e

echo "Deploying Production ArgoCD Application..."

# Create namespace
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

# Create secrets (you'll need to provide actual values)
echo "⚠️  Please create production secrets manually:"
echo "kubectl create secret generic nodejs-app-secrets \\"
echo "  --from-literal=API_KEY='your-key' \\"
echo "  --from-literal=JWT_SECRET='your-secret' \\"
echo "  --from-literal=DATABASE_URL='your-url' \\"
echo "  --namespace=production"
echo ""
read -p "Press enter after creating secrets..."

# Deploy ArgoCD application
kubectl apply -f k8s/argocd/production-app.yaml

# Wait for application to be created
sleep 5

# Show status
argocd app get nodejs-app-production

echo ""
echo "✅ Production application deployed!"
echo "Next steps:"
echo "1. Sync the application: argocd app sync nodejs-app-production"
echo "2. Verify pods: kubectl get pods -n production"
echo "3. Test health: kubectl port-forward -n production svc/production-nodejs-app 8080:80"
```

Make it executable:
```bash
chmod +x deploy-production.sh
./deploy-production.sh
```
