# Quick Start: Kubernetes + ArgoCD Setup

This guide will get you up and running with a complete CI/CD pipeline in under 10 minutes.

## 🚀 Quick Setup (3 Commands)

```bash
# 1. Set up Kubernetes cluster and ArgoCD
./setup-k8s-argocd.sh

# 2. Configure GHCR image pull secrets
./setup-ghcr-secrets.sh

# 3. Update and deploy ArgoCD applications (see below)
```

## 📋 Prerequisites

- Docker Desktop running
- kubectl installed (`brew install kubectl`)
- minikube installed (`brew install minikube`)
- GitHub Personal Access Token with `read:packages` permission

## Step-by-Step Instructions

### 1. Start Kubernetes Cluster with ArgoCD

Run the automated setup script:

```bash
./setup-k8s-argocd.sh
```

This script will:
- ✅ Start Minikube cluster
- ✅ Enable necessary addons
- ✅ Install ArgoCD
- ✅ Create staging and production namespaces
- ✅ Configure ArgoCD access
- ✅ Display admin credentials

**Save the ArgoCD admin password shown at the end!**

### 2. Configure GitHub Container Registry Access

Create a GitHub Personal Access Token:
1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scope: `read:packages`
4. Generate and copy the token

Run the secrets setup script:

```bash
./setup-ghcr-secrets.sh
```

Enter your:
- GitHub username
- Personal Access Token (PAT)
- GitHub email

### 3. Update ArgoCD Application Manifests

Update the repository URL in the ArgoCD application files:

**Edit `k8s/argocd/staging-app.yaml`:**
```yaml
spec:
  source:
    repoURL: https://github.com/YOUR-USERNAME/YOUR-REPO  # Update this
```

**Edit `k8s/argocd/production-app.yaml`:**
```yaml
spec:
  source:
    repoURL: https://github.com/YOUR-USERNAME/YOUR-REPO  # Update this
```

### 4. Deploy ArgoCD Applications

```bash
# Deploy staging application
kubectl apply -f k8s/argocd/staging-app.yaml

# Verify application is created
kubectl get applications -n argocd

# Check application status
kubectl get application nodejs-app-staging -n argocd
```

### 5. Access ArgoCD UI

**Option A: Port Forward (Recommended)**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then open: https://localhost:8080

**Option B: Minikube Service**
```bash
minikube service argocd-server -n argocd
```

Login with:
- Username: `admin`
- Password: (from setup script output)

### 6. Sync Your Application

**Via ArgoCD UI:**
1. Click on `nodejs-app-staging`
2. Click "SYNC" button
3. Click "SYNCHRONIZE"

**Via kubectl:**
```bash
# Install ArgoCD CLI (optional)
brew install argocd

# Login
argocd login localhost:8080 --username admin --insecure

# Sync application
argocd app sync nodejs-app-staging

# Watch sync progress
argocd app wait nodejs-app-staging
```

### 7. Access Your Application

```bash
# Get service URL
minikube service staging-nodejs-app -n staging --url

# Test health endpoint
curl $(minikube service staging-nodejs-app -n staging --url)/health

# Or use port forwarding
kubectl port-forward svc/staging-nodejs-app -n staging 3000:3000

# Then access: http://localhost:3000/health
```

## 🔄 Test the Complete CI/CD Pipeline

Now that everything is set up, test the full pipeline:

### 1. Make a code change
```bash
# Edit src/server.js or any file
echo "// Test change" >> src/server.js
```

### 2. Commit and push to main branch
```bash
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
```

### 3. Watch the magic happen! ✨

**GitHub Actions will:**
1. Run CI pipeline (lint, test, build)
2. Build and push Docker image to GHCR
3. Update `k8s/overlays/staging/kustomization.yaml`
4. Commit changes back to repo

**ArgoCD will:**
1. Detect the manifest change
2. Automatically sync to Kubernetes
3. Deploy new version with rolling update
4. Verify health checks

**Monitor progress:**
```bash
# Watch GitHub Actions
# Go to: https://github.com/YOUR-USERNAME/YOUR-REPO/actions

# Watch ArgoCD sync
kubectl get applications -n argocd -w

# Watch pods rolling update
kubectl get pods -n staging -w

# Check application logs
kubectl logs -f deployment/staging-nodejs-app -n staging
```

## 🎯 Verification Checklist

- [ ] Minikube cluster is running: `minikube status`
- [ ] ArgoCD is accessible: `kubectl get pods -n argocd`
- [ ] Namespaces created: `kubectl get namespaces`
- [ ] GHCR secrets created: `kubectl get secret ghcr-secret -n staging`
- [ ] ArgoCD application deployed: `kubectl get applications -n argocd`
- [ ] Application synced: Check ArgoCD UI
- [ ] Pods running: `kubectl get pods -n staging`
- [ ] Service accessible: `minikube service staging-nodejs-app -n staging --url`
- [ ] Health check works: `curl <service-url>/health`

## 🛠️ Useful Commands

```bash
# View all resources in staging
kubectl get all -n staging

# View application logs
kubectl logs -f deployment/staging-nodejs-app -n staging

# Describe pod (for troubleshooting)
kubectl describe pod <pod-name> -n staging

# Restart deployment
kubectl rollout restart deployment/staging-nodejs-app -n staging

# View deployment history
kubectl rollout history deployment/staging-nodejs-app -n staging

# Rollback to previous version
kubectl rollout undo deployment/staging-nodejs-app -n staging

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access application
kubectl port-forward svc/staging-nodejs-app -n staging 3000:3000
```

## 🐛 Troubleshooting

### Pods not starting
```bash
# Check pod status
kubectl get pods -n staging

# Describe pod for details
kubectl describe pod <pod-name> -n staging

# Check logs
kubectl logs <pod-name> -n staging
```

### ImagePullBackOff error
```bash
# Verify secret exists
kubectl get secret ghcr-secret -n staging

# Recreate secret
./setup-ghcr-secrets.sh

# Check if image exists in GHCR
# Go to: https://github.com/YOUR-USERNAME?tab=packages
```

### ArgoCD not syncing
```bash
# Check application status
kubectl get application nodejs-app-staging -n argocd -o yaml

# Force refresh
kubectl patch application nodejs-app-staging -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Minikube issues
```bash
# Check status
minikube status

# View logs
minikube logs

# Restart minikube
minikube stop
minikube start

# Delete and recreate (nuclear option)
minikube delete
./setup-k8s-argocd.sh
```

## 🧹 Cleanup

When you're done:

```bash
# Delete applications
kubectl delete -f k8s/argocd/staging-app.yaml

# Stop minikube
minikube stop

# Delete cluster (if you want to start fresh)
minikube delete
```

## 📚 Next Steps

- Set up production deployment (Task 9)
- Configure monitoring and logging (Task 11)
- Add custom domain with Ingress
- Set up automated testing in staging
- Configure Slack/email notifications

## 🆘 Need Help?

- Full documentation: `docs/kubernetes-argocd-setup.md`
- ArgoCD docs: https://argo-cd.readthedocs.io/
- Minikube docs: https://minikube.sigs.k8s.io/docs/
