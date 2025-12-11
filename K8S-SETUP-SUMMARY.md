# Kubernetes & ArgoCD Setup - Complete Guide

## 🎯 What You Get

A complete local Kubernetes cluster with:
- ✅ Minikube cluster (4 CPUs, 8GB RAM)
- ✅ ArgoCD for GitOps deployments
- ✅ Staging and Production namespaces
- ✅ Automated CI/CD pipeline integration
- ✅ GitHub Container Registry integration

## 🚀 Quick Start (3 Steps)

### Step 1: Set Up Cluster and ArgoCD
```bash
./setup-k8s-argocd.sh
```
**What it does:**
- Starts Minikube cluster
- Installs ArgoCD
- Creates namespaces
- Displays admin credentials

**Time:** ~3-5 minutes

### Step 2: Configure GHCR Access
```bash
./setup-ghcr-secrets.sh
```
**What you need:**
- GitHub username
- GitHub Personal Access Token (with `read:packages` scope)
- GitHub email

**Create PAT:** https://github.com/settings/tokens

**Time:** ~1 minute

### Step 3: Deploy Applications

**Update repository URLs in:**
- `k8s/argocd/staging-app.yaml`
- `k8s/argocd/production-app.yaml`

Change `repoURL` to your GitHub repository.

**Deploy:**
```bash
kubectl apply -f k8s/argocd/staging-app.yaml
```

**Time:** ~1 minute

## 📊 Check Status

```bash
./check-k8s-status.sh
```

This shows:
- Minikube status
- ArgoCD status and credentials
- Namespace status
- Application pods
- Services
- Quick access commands

## 🔄 Complete CI/CD Flow

Once set up, here's what happens when you push to `main`:

```
┌─────────────────────────────────────────────────────────┐
│ 1. Developer pushes to main branch                      │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ 2. GitHub Actions CI Pipeline                           │
│    - Lint code                                           │
│    - Run tests                                           │
│    - Build Docker image                                  │
│    - Push to GHCR                                        │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ 3. GitHub Actions CD Pipeline (Staging)                 │
│    - Build multi-platform image                         │
│    - Tag with commit SHA                                 │
│    - Update k8s/overlays/staging/kustomization.yaml     │
│    - Commit changes back to repo                        │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ 4. ArgoCD Detects Change                                │
│    - Monitors Git repository                            │
│    - Detects manifest update                            │
│    - Auto-syncs to Kubernetes                           │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ 5. Kubernetes Deploys                                   │
│    - Rolling update (zero downtime)                     │
│    - Health checks                                       │
│    - New version live!                                   │
└─────────────────────────────────────────────────────────┘
```

## 🧪 Test the Pipeline

### 1. Make a change
```bash
echo "// Test change" >> src/server.js
```

### 2. Commit and push
```bash
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
```

### 3. Watch it deploy!

**GitHub Actions:**
```
https://github.com/YOUR-USERNAME/YOUR-REPO/actions
```

**ArgoCD UI:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080
```

**Watch pods update:**
```bash
kubectl get pods -n staging -w
```

**Check logs:**
```bash
kubectl logs -f deployment/staging-nodejs-app -n staging
```

## 🌐 Access Your Application

### Option 1: Minikube Service (Easiest)
```bash
minikube service staging-nodejs-app -n staging
```
This opens your browser automatically!

### Option 2: Port Forward
```bash
kubectl port-forward svc/staging-nodejs-app -n staging 3000:3000
```
Then open: http://localhost:3000/health

### Option 3: Get URL
```bash
minikube service staging-nodejs-app -n staging --url
curl $(minikube service staging-nodejs-app -n staging --url)/health
```

## 📁 Files Created

### Setup Scripts
- `setup-k8s-argocd.sh` - Automated cluster and ArgoCD setup
- `setup-ghcr-secrets.sh` - GHCR credentials configuration
- `check-k8s-status.sh` - Status checker

### Documentation
- `docs/kubernetes-argocd-setup.md` - Detailed manual setup guide
- `docs/QUICK-START-K8S.md` - Quick start guide
- `K8S-SETUP-SUMMARY.md` - This file

### Kubernetes Manifests
- `k8s/base/` - Base Kubernetes resources
- `k8s/overlays/staging/` - Staging environment config
- `k8s/overlays/production/` - Production environment config
- `k8s/argocd/` - ArgoCD application definitions

### GitHub Actions Workflows
- `.github/workflows/ci.yml` - Continuous Integration
- `.github/workflows/cd-staging.yml` - Staging Deployment

## 🛠️ Useful Commands

### Cluster Management
```bash
# Start cluster
minikube start

# Stop cluster
minikube stop

# Delete cluster
minikube delete

# Check status
./check-k8s-status.sh
```

### ArgoCD
```bash
# Access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Sync application
kubectl patch application nodejs-app-staging -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### Application Management
```bash
# View all resources
kubectl get all -n staging

# View pods
kubectl get pods -n staging

# View logs
kubectl logs -f deployment/staging-nodejs-app -n staging

# Restart deployment
kubectl rollout restart deployment/staging-nodejs-app -n staging

# Rollback
kubectl rollout undo deployment/staging-nodejs-app -n staging

# View history
kubectl rollout history deployment/staging-nodejs-app -n staging
```

### Debugging
```bash
# Describe pod
kubectl describe pod <pod-name> -n staging

# Get pod logs
kubectl logs <pod-name> -n staging

# Execute command in pod
kubectl exec -it <pod-name> -n staging -- /bin/sh

# Check events
kubectl get events -n staging --sort-by='.lastTimestamp'
```

## 🐛 Common Issues

### ImagePullBackOff
**Problem:** Pod can't pull image from GHCR

**Solution:**
```bash
# Recreate secrets
./setup-ghcr-secrets.sh

# Verify secret
kubectl get secret ghcr-secret -n staging -o yaml

# Check if image exists
# Visit: https://github.com/YOUR-USERNAME?tab=packages
```

### ArgoCD Not Syncing
**Problem:** ArgoCD doesn't detect changes

**Solution:**
```bash
# Force refresh
kubectl patch application nodejs-app-staging -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Pods CrashLoopBackOff
**Problem:** Application keeps crashing

**Solution:**
```bash
# Check logs
kubectl logs <pod-name> -n staging

# Check events
kubectl describe pod <pod-name> -n staging

# Verify environment variables
kubectl get configmap nodejs-app-config -n staging -o yaml
```

## 📚 Next Steps

1. ✅ Set up Kubernetes and ArgoCD (You're here!)
2. ⏭️ Test the complete CI/CD pipeline
3. ⏭️ Set up production deployment (Task 9)
4. ⏭️ Add monitoring and logging (Task 11)
5. ⏭️ Configure custom domain with Ingress
6. ⏭️ Set up automated testing in staging

## 🆘 Need Help?

- **Detailed docs:** `docs/kubernetes-argocd-setup.md`
- **Quick start:** `docs/QUICK-START-K8S.md`
- **Check status:** `./check-k8s-status.sh`
- **ArgoCD docs:** https://argo-cd.readthedocs.io/
- **Minikube docs:** https://minikube.sigs.k8s.io/docs/

## 🎉 You're Ready!

Your complete CI/CD pipeline is set up! Push to `main` and watch your code automatically deploy to Kubernetes via ArgoCD.

**Happy deploying! 🚀**
