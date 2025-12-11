# Kubernetes and ArgoCD Setup Guide

This guide will help you set up a local Kubernetes cluster using Minikube and install ArgoCD for GitOps-based deployments.

## Prerequisites

✅ You already have:
- Docker Desktop installed and running
- kubectl installed
- minikube installed

## Step 1: Start Minikube Cluster

Start a local Kubernetes cluster with sufficient resources:

```bash
# Start minikube with Docker driver
minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=20g

# Verify cluster is running
minikube status

# Check kubectl can connect
kubectl cluster-info
kubectl get nodes
```

## Step 2: Enable Minikube Addons

Enable useful addons for local development:

```bash
# Enable metrics server (for resource monitoring)
minikube addons enable metrics-server

# Enable ingress (for external access)
minikube addons enable ingress

# List all enabled addons
minikube addons list
```

## Step 3: Install ArgoCD

Install ArgoCD in your cluster:

```bash
# Create argocd namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD pods to be ready (this may take 2-3 minutes)
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Verify installation
kubectl get pods -n argocd
```

## Step 4: Access ArgoCD UI

### Option A: Port Forward (Recommended for local development)

```bash
# Port forward ArgoCD server to localhost
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access ArgoCD UI at: https://localhost:8080
# (Accept the self-signed certificate warning)
```

### Option B: Expose via Minikube Service

```bash
# Patch ArgoCD server to use NodePort
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# Get the URL
minikube service argocd-server -n argocd --url
```

## Step 5: Get ArgoCD Admin Password

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Login credentials:
# Username: admin
# Password: (output from above command)
```

## Step 6: Install ArgoCD CLI (Optional but Recommended)

```bash
# Install ArgoCD CLI on macOS
brew install argocd

# Login via CLI
argocd login localhost:8080 --username admin --password <password-from-step-5> --insecure

# Change admin password (recommended)
argocd account update-password
```

## Step 7: Create Namespaces for Environments

```bash
# Create staging namespace
kubectl create namespace staging

# Create production namespace
kubectl create namespace production

# Verify namespaces
kubectl get namespaces
```

## Step 8: Configure GitHub Container Registry Access

Create a secret for pulling images from GHCR:

```bash
# Replace with your GitHub username and Personal Access Token (PAT)
# PAT needs 'read:packages' permission
export GITHUB_USERNAME="your-github-username"
export GITHUB_TOKEN="your-github-pat"

# Create image pull secret for staging
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USERNAME \
  --docker-password=$GITHUB_TOKEN \
  --docker-email=your-email@example.com \
  -n staging

# Create image pull secret for production
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USERNAME \
  --docker-password=$GITHUB_TOKEN \
  --docker-email=your-email@example.com \
  -n production
```

## Step 9: Deploy ArgoCD Applications

Before deploying, update the repository URL in the ArgoCD application manifests:

```bash
# Edit staging app
# Update repoURL in k8s/argocd/staging-app.yaml to your GitHub repo URL

# Edit production app
# Update repoURL in k8s/argocd/production-app.yaml to your GitHub repo URL
```

Then apply the ArgoCD applications:

```bash
# Deploy staging application
kubectl apply -f k8s/argocd/staging-app.yaml

# Deploy production application (optional for now)
kubectl apply -f k8s/argocd/production-app.yaml

# Verify applications are created
kubectl get applications -n argocd
```

## Step 10: Sync Applications

### Via ArgoCD UI:
1. Open https://localhost:8080
2. Login with admin credentials
3. Click on your application
4. Click "SYNC" button
5. Click "SYNCHRONIZE"

### Via ArgoCD CLI:
```bash
# Sync staging application
argocd app sync nodejs-app-staging

# Watch sync progress
argocd app wait nodejs-app-staging

# Check application status
argocd app get nodejs-app-staging
```

## Step 11: Access Your Application

```bash
# Get the service URL for staging
minikube service staging-nodejs-app -n staging --url

# Test the health endpoint
curl $(minikube service staging-nodejs-app -n staging --url)/health

# Or use port forwarding
kubectl port-forward svc/staging-nodejs-app -n staging 3000:3000

# Then access: http://localhost:3000/health
```

## Verification Checklist

- [ ] Minikube cluster is running
- [ ] ArgoCD is installed and accessible
- [ ] ArgoCD admin password retrieved
- [ ] Staging and production namespaces created
- [ ] GHCR image pull secrets created
- [ ] ArgoCD applications deployed
- [ ] Applications synced successfully
- [ ] Application is accessible via service URL

## Troubleshooting

### Pods not starting
```bash
# Check pod status
kubectl get pods -n staging

# Describe pod for details
kubectl describe pod <pod-name> -n staging

# Check logs
kubectl logs <pod-name> -n staging
```

### Image pull errors
```bash
# Verify secret exists
kubectl get secret ghcr-secret -n staging

# Check if secret is referenced in deployment
kubectl get deployment staging-nodejs-app -n staging -o yaml | grep imagePullSecrets
```

### ArgoCD sync issues
```bash
# Check application status
argocd app get nodejs-app-staging

# View sync logs
argocd app logs nodejs-app-staging

# Force refresh
argocd app get nodejs-app-staging --refresh
```

### Minikube issues
```bash
# Stop minikube
minikube stop

# Delete and recreate cluster
minikube delete
minikube start --driver=docker --cpus=4 --memory=8192

# Check minikube logs
minikube logs
```

## Useful Commands

```bash
# View all resources in staging
kubectl get all -n staging

# View ArgoCD applications
kubectl get applications -n argocd

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access your app
kubectl port-forward svc/staging-nodejs-app -n staging 3000:3000

# View application logs
kubectl logs -f deployment/staging-nodejs-app -n staging

# Restart deployment
kubectl rollout restart deployment/staging-nodejs-app -n staging

# View deployment history
kubectl rollout history deployment/staging-nodejs-app -n staging
```

## Next Steps

1. Push code to main branch to trigger CD pipeline
2. Watch GitHub Actions build and push image
3. See ArgoCD automatically sync the new version
4. Verify deployment in Kubernetes cluster
5. Test the application endpoints

## Cleanup

When you're done:

```bash
# Delete ArgoCD applications
kubectl delete -f k8s/argocd/staging-app.yaml
kubectl delete -f k8s/argocd/production-app.yaml

# Uninstall ArgoCD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Stop minikube
minikube stop

# Delete minikube cluster (if you want to start fresh)
minikube delete
```
