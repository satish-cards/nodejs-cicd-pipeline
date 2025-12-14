# ArgoCD Setup and Configuration Guide

This guide covers ArgoCD installation, configuration, and usage for GitOps-based continuous deployment.

## Table of Contents

1. [What is ArgoCD?](#what-is-argocd)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Creating Applications](#creating-applications)
5. [Sync Policies](#sync-policies)
6. [Managing Applications](#managing-applications)
7. [Troubleshooting](#troubleshooting)

## What is ArgoCD?

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It:

- **Monitors Git repositories** for changes to Kubernetes manifests
- **Automatically syncs** cluster state to match Git state
- **Provides visibility** into application deployment status
- **Enables rollbacks** by reverting Git commits
- **Supports multiple environments** with different sync policies

### Key Concepts

**Application**: A group of Kubernetes resources defined in a Git repository

**Sync**: The process of making the cluster state match the Git state

**Health**: The operational status of deployed resources

**Sync Policy**: Rules for when and how to sync (automatic vs manual)

**Self-Heal**: Automatically revert manual changes to match Git

**Prune**: Automatically delete resources not defined in Git

## Installation

### Prerequisites

- Kubernetes cluster running (Minikube, kind, or cloud provider)
- kubectl configured to access the cluster
- Cluster admin permissions

### Quick Installation

```bash
# Create argocd namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready (2-3 minutes)
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Verify installation
kubectl get pods -n argocd
```

### Expected Output

```
NAME                                  READY   STATUS    RESTARTS   AGE
argocd-application-controller-0       1/1     Running   0          2m
argocd-dex-server-xxx                 1/1     Running   0          2m
argocd-redis-xxx                      1/1     Running   0          2m
argocd-repo-server-xxx                1/1     Running   0          2m
argocd-server-xxx                     1/1     Running   0          2m
```

## Configuration

### Accessing ArgoCD UI

#### Option 1: Port Forward (Recommended for local)

```bash
# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access UI at: https://localhost:8080
# (Accept self-signed certificate warning)
```

#### Option 2: NodePort (Minikube)

```bash
# Patch service to use NodePort
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# Get URL
minikube service argocd-server -n argocd --url
```

#### Option 3: LoadBalancer (Cloud)

```bash
# Patch service to use LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get external IP
kubectl get svc argocd-server -n argocd
```

### Getting Admin Password

```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

**Login Credentials**:
- Username: `admin`
- Password: (output from above command)

### Installing ArgoCD CLI

The CLI provides command-line access to ArgoCD functionality.

**macOS**:
```bash
brew install argocd
```

**Linux**:
```bash
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```

**Windows**:
```powershell
# Download from: https://github.com/argoproj/argo-cd/releases/latest
# Add to PATH
```

### Login via CLI

```bash
# Login (with port-forward running)
argocd login localhost:8080 --username admin --password <password> --insecure

# Change admin password (recommended)
argocd account update-password
```

## Creating Applications

### Application Structure

An ArgoCD Application defines:
- **Source**: Git repository and path
- **Destination**: Kubernetes cluster and namespace
- **Sync Policy**: Automatic or manual sync

### Example Application Manifest

**Staging Application** (`k8s/argocd/staging-app.yaml`):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nodejs-app-staging
  namespace: argocd
spec:
  project: default
  
  # Source: Where to get manifests
  source:
    repoURL: https://github.com/YOUR_USERNAME/nodejs-cicd-pipeline
    targetRevision: main
    path: k8s/overlays/staging
  
  # Destination: Where to deploy
  destination:
    server: https://kubernetes.default.svc
    namespace: staging
  
  # Sync Policy: How to sync
  syncPolicy:
    automated:
      prune: true      # Delete resources not in Git
      selfHeal: true   # Revert manual changes
    syncOptions:
      - CreateNamespace=true  # Create namespace if missing
```

**Production Application** (`k8s/argocd/production-app.yaml`):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nodejs-app-production
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/YOUR_USERNAME/nodejs-cicd-pipeline
    targetRevision: main
    path: k8s/overlays/production
  
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  # Manual sync for production
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    # No automated sync - requires manual approval
```

### Deploying Applications

```bash
# Update repoURL in manifests first
sed -i 's|YOUR_USERNAME|your-github-username|g' k8s/argocd/*.yaml

# Deploy staging application
kubectl apply -f k8s/argocd/staging-app.yaml

# Deploy production application
kubectl apply -f k8s/argocd/production-app.yaml

# Verify applications created
kubectl get applications -n argocd
```

## Sync Policies

### Automatic Sync

**When to use**: Staging, development environments

**Configuration**:
```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

**Behavior**:
- Syncs automatically when Git changes
- Deletes resources not in Git (prune)
- Reverts manual cluster changes (selfHeal)
- No human approval needed

### Manual Sync

**When to use**: Production environments

**Configuration**:
```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
  # No automated section
```

**Behavior**:
- Requires manual sync trigger
- Human approval before changes
- More control over deployments
- Safer for production

### Sync Options

| Option | Description | Use Case |
|--------|-------------|----------|
| `CreateNamespace=true` | Create namespace if missing | All environments |
| `PruneLast=true` | Delete resources after new ones are healthy | Zero-downtime |
| `ApplyOutOfSyncOnly=true` | Only apply out-of-sync resources | Large applications |
| `RespectIgnoreDifferences=true` | Ignore specified differences | Dynamic fields |

## Managing Applications

### Via ArgoCD UI

1. **Open UI**: https://localhost:8080
2. **Login** with admin credentials
3. **View Applications**: See all deployed apps
4. **Click Application**: View details
5. **Sync**: Click "SYNC" button to deploy
6. **Rollback**: Use "History and Rollback" tab

### Via ArgoCD CLI

#### List Applications

```bash
# List all applications
argocd app list

# Get application details
argocd app get nodejs-app-staging
```

#### Sync Applications

```bash
# Sync application
argocd app sync nodejs-app-staging

# Sync and wait for completion
argocd app sync nodejs-app-staging --wait

# Sync specific resource
argocd app sync nodejs-app-staging --resource Deployment:staging-nodejs-app
```

#### View Application Status

```bash
# Get application status
argocd app get nodejs-app-staging

# Watch sync progress
argocd app wait nodejs-app-staging

# View application logs
argocd app logs nodejs-app-staging
```

#### Rollback Applications

```bash
# View deployment history
argocd app history nodejs-app-staging

# Rollback to previous version
argocd app rollback nodejs-app-staging

# Rollback to specific revision
argocd app rollback nodejs-app-staging 5
```

#### Delete Applications

```bash
# Delete application (keeps resources)
argocd app delete nodejs-app-staging

# Delete application and resources
argocd app delete nodejs-app-staging --cascade
```

### Via kubectl

```bash
# List applications
kubectl get applications -n argocd

# Describe application
kubectl describe application nodejs-app-staging -n argocd

# Delete application
kubectl delete application nodejs-app-staging -n argocd
```

## Advanced Configuration

### Health Assessment

ArgoCD automatically assesses health of common Kubernetes resources:

- **Healthy**: Resource is running correctly
- **Progressing**: Resource is being created/updated
- **Degraded**: Resource has issues
- **Suspended**: Resource is intentionally stopped
- **Missing**: Resource should exist but doesn't
- **Unknown**: Health cannot be determined

### Custom Health Checks

Define custom health checks for CRDs:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  resource.customizations: |
    custom.resource/MyResource:
      health.lua: |
        hs = {}
        if obj.status ~= nil then
          if obj.status.phase == "Running" then
            hs.status = "Healthy"
            hs.message = "Resource is running"
            return hs
          end
        end
        hs.status = "Progressing"
        hs.message = "Waiting for resource"
        return hs
```

### Ignore Differences

Ignore specific fields that change frequently:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nodejs-app-staging
spec:
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas  # Ignore replica count changes
```

### Resource Hooks

Execute actions at specific sync phases:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: database-migration
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: migrate-tool
        command: ["migrate", "up"]
      restartPolicy: Never
```

**Hook Types**:
- `PreSync`: Before sync
- `Sync`: During sync
- `PostSync`: After sync
- `SyncFail`: On sync failure

## Monitoring and Observability

### Application Metrics

ArgoCD exposes Prometheus metrics:

```bash
# Port forward metrics endpoint
kubectl port-forward svc/argocd-metrics -n argocd 8082:8082

# View metrics
curl http://localhost:8082/metrics
```

**Key Metrics**:
- `argocd_app_info`: Application information
- `argocd_app_sync_total`: Sync count
- `argocd_app_health_status`: Health status

### Notifications

Configure notifications for sync events:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  trigger.on-sync-succeeded: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-sync-succeeded]
  template.app-sync-succeeded: |
    message: |
      Application {{.app.metadata.name}} synced successfully
```

### Audit Logs

View ArgoCD audit logs:

```bash
# View ArgoCD server logs
kubectl logs -f deployment/argocd-server -n argocd

# View application controller logs
kubectl logs -f statefulset/argocd-application-controller -n argocd
```

## Troubleshooting

### Application Won't Sync

**Symptoms**:
- Application stuck in "OutOfSync"
- Sync fails with errors

**Solutions**:

```bash
# Check application status
argocd app get nodejs-app-staging

# View sync errors
argocd app get nodejs-app-staging --show-operation

# View differences
argocd app diff nodejs-app-staging

# Force hard refresh
argocd app get nodejs-app-staging --hard-refresh

# Try manual sync
argocd app sync nodejs-app-staging
```

### Application Shows Degraded

**Symptoms**:
- Health status is "Degraded"
- Resources not healthy

**Solutions**:

```bash
# Check resource status
kubectl get all -n staging

# Check pod logs
kubectl logs -f deployment/staging-nodejs-app -n staging

# Check events
kubectl get events -n staging --sort-by='.lastTimestamp'

# Describe unhealthy resources
kubectl describe pod <pod-name> -n staging
```

### Git Repository Connection Issues

**Symptoms**:
- "Unable to connect to repository"
- Authentication errors

**Solutions**:

```bash
# Check repository URL is correct
argocd app get nodejs-app-staging -o yaml | grep repoURL

# Test repository access
argocd repo list

# Add repository credentials if private
argocd repo add https://github.com/username/repo \
  --username <username> \
  --password <token>
```

### ArgoCD UI Not Accessible

**Symptoms**:
- Cannot access UI
- Connection refused

**Solutions**:

```bash
# Check ArgoCD pods are running
kubectl get pods -n argocd

# Check ArgoCD server logs
kubectl logs -f deployment/argocd-server -n argocd

# Restart port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Check service
kubectl get svc argocd-server -n argocd
```

### Sync Takes Too Long

**Symptoms**:
- Sync operation times out
- Resources not updating

**Solutions**:

```bash
# Increase sync timeout
argocd app set nodejs-app-staging --sync-option Timeout=600

# Check for large resources
kubectl get all -n staging

# Check ArgoCD controller logs
kubectl logs -f statefulset/argocd-application-controller -n argocd
```

## Best Practices

### Repository Structure

1. **Separate environments**: Use overlays for staging/production
2. **Use Kustomize or Helm**: For environment-specific configuration
3. **Keep manifests simple**: Avoid complex templating
4. **Version everything**: Tag releases in Git

### Application Configuration

1. **Use automatic sync for staging**: Fast feedback
2. **Use manual sync for production**: Safety and control
3. **Enable prune**: Keep cluster clean
4. **Enable self-heal**: Prevent configuration drift
5. **Set resource limits**: Prevent resource exhaustion

### Security

1. **Use RBAC**: Limit who can sync applications
2. **Use separate projects**: Isolate teams/applications
3. **Enable audit logging**: Track all changes
4. **Use Git webhooks**: Faster sync detection
5. **Rotate credentials**: Regularly update passwords

### Monitoring

1. **Set up notifications**: Know when syncs fail
2. **Monitor metrics**: Track sync frequency and duration
3. **Review logs regularly**: Catch issues early
4. **Use health checks**: Ensure applications are healthy
5. **Test rollbacks**: Practice disaster recovery

## Related Documentation

- [CI/CD Overview](ci-cd-overview.md) - Complete pipeline architecture
- [Deployment Guide](deployment-guide.md) - Deployment procedures
- [Kubernetes Setup](kubernetes-argocd-setup.md) - Kubernetes installation

## Additional Resources

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD GitHub Repository](https://github.com/argoproj/argo-cd)
- [GitOps Principles](https://www.gitops.tech/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Conclusion

ArgoCD provides a powerful GitOps workflow for Kubernetes deployments:

- ✅ Declarative configuration in Git
- ✅ Automatic synchronization
- ✅ Easy rollbacks
- ✅ Complete audit trail
- ✅ Multi-environment support

By following this guide, you can set up and manage ArgoCD for reliable, automated deployments.
