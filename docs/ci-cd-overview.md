# CI/CD Pipeline Architecture Overview

## Introduction

This document provides a comprehensive overview of the CI/CD (Continuous Integration/Continuous Deployment) pipeline architecture for the Node.js application. The pipeline automates the entire software delivery process from code commit to production deployment, ensuring code quality, consistency, and reliability.

## Pipeline Philosophy

The CI/CD pipeline follows these core principles:

1. **Automation First**: Every step from testing to deployment is automated
2. **Fast Feedback**: Developers get immediate feedback on code quality
3. **GitOps**: Git is the single source of truth for both code and infrastructure
4. **Environment Parity**: Staging mirrors production as closely as possible
5. **Safety**: Multiple checks and manual approval gates prevent bad deployments
6. **Observability**: Every step is logged and monitored

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Developer Workflow                        │
├─────────────────────────────────────────────────────────────────┤
│  Local Dev → Feature Branch → Pull Request → Main Branch        │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GitHub Actions CI/CD                        │
├─────────────────────────────────────────────────────────────────┤
│  1. Lint & Test                                                  │
│  2. Build Docker Image                                           │
│  3. Push to GHCR (GitHub Container Registry)                     │
│  4. Update Kubernetes Manifests                                  │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                         ArgoCD GitOps                            │
├─────────────────────────────────────────────────────────────────┤
│  Monitors Git → Syncs K8s Cluster → Health Checks               │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Deployment Environments                       │
├─────────────────────────────────────────────────────────────────┤
│  Staging (Auto) → Production (Manual Approval)                   │
└─────────────────────────────────────────────────────────────────┘
```

## Pipeline Stages

### Stage 1: Development

**What Happens**:
- Developer writes code locally
- Runs tests and linting locally
- Commits changes to feature branch
- Pushes to GitHub

**Tools**:
- Git for version control
- npm for dependency management
- Jest for local testing
- ESLint for code quality

**Best Practices**:
- Create feature branches from main
- Write tests for new features
- Run `npm test` and `npm run lint` before committing
- Write clear commit messages

### Stage 2: Continuous Integration (CI)

**What Happens**:
- GitHub Actions automatically triggers on push
- Code is checked out
- Dependencies are installed
- Code is linted for quality
- Tests are executed with coverage
- Docker image is built
- Image is pushed to GitHub Container Registry

**Tools**:
- GitHub Actions for automation
- ESLint for code quality
- Jest for testing
- Docker for containerization
- GHCR for image storage

**Quality Gates**:
- ✅ All linting rules must pass
- ✅ All tests must pass
- ✅ Docker image must build successfully
- ✅ Health check must respond

**Duration**: ~2 minutes

See [GitHub Actions Documentation](github-actions.md) for detailed workflow information.

### Stage 3: Continuous Deployment - Staging (CD)

**What Happens**:
- Triggered automatically when CI passes on main branch
- Docker image is tagged with commit SHA
- Kubernetes manifests are updated with new image tag
- Changes are committed back to Git
- ArgoCD detects the change
- ArgoCD syncs the Kubernetes cluster
- Rolling update deploys new version
- Health checks verify deployment

**Tools**:
- GitHub Actions for automation
- Kustomize for manifest management
- ArgoCD for GitOps deployment
- Kubernetes for orchestration

**Deployment Strategy**:
- Rolling update (zero downtime)
- 2 replicas in staging
- Automatic sync enabled
- Self-healing enabled

**Duration**: ~3-5 minutes

### Stage 4: Continuous Deployment - Production (CD)

**What Happens**:
- Triggered manually via GitHub Actions UI
- **Manual approval required** (24-hour timeout)
- Current production state is backed up
- Kubernetes manifests are updated
- Changes are committed to Git
- ArgoCD syncs production cluster
- Rolling update deploys new version
- Health checks verify deployment
- **Automatic rollback on failure**
- Deployment notification sent

**Tools**:
- GitHub Actions for automation
- GitHub Environments for approval
- Kustomize for manifest management
- ArgoCD for GitOps deployment
- Kubernetes for orchestration

**Deployment Strategy**:
- Rolling update (zero downtime)
- 3 replicas in production
- Manual sync (approval required)
- Self-healing enabled
- Automatic rollback on health check failure

**Duration**: ~5-10 minutes (plus approval time)

See [Deployment Guide](deployment-guide.md) for step-by-step instructions.

## GitOps with ArgoCD

### What is GitOps?

GitOps is a deployment methodology where:
- Git is the single source of truth
- All infrastructure and application configuration is stored in Git
- Changes are made via Git commits
- Automated processes sync Git state to cluster state

### How ArgoCD Works

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│              │         │              │         │              │
│  Git Repo    │────────▶│   ArgoCD     │────────▶│  Kubernetes  │
│  (Desired)   │  Polls  │  (Compares)  │  Syncs  │   (Actual)   │
│              │         │              │         │              │
└──────────────┘         └──────────────┘         └──────────────┘
```

**ArgoCD Responsibilities**:
1. **Monitor**: Continuously watches Git repository for changes
2. **Compare**: Compares desired state (Git) with actual state (cluster)
3. **Sync**: Applies changes to make actual state match desired state
4. **Health Check**: Monitors application health and reports status
5. **Self-Heal**: Automatically reverts manual changes to cluster

**Benefits**:
- ✅ Declarative configuration
- ✅ Version control for infrastructure
- ✅ Audit trail of all changes
- ✅ Easy rollback (just revert Git commit)
- ✅ Disaster recovery (cluster can be rebuilt from Git)

See [ArgoCD Setup Guide](argocd-setup.md) for installation instructions.

## Environment Strategy

### Development Environment

**Purpose**: Local development and testing

**Characteristics**:
- Runs on developer's machine
- Uses Docker Compose or local Node.js
- Hot reload enabled
- Detailed error messages
- Debug logging enabled

**Configuration**:
- NODE_ENV=development
- LOG_LEVEL=debug
- ENABLE_DETAILED_ERRORS=true

### Staging Environment

**Purpose**: Pre-production testing and validation

**Characteristics**:
- Mirrors production configuration
- Automatic deployment from main branch
- 2 replicas for redundancy
- Production-like data (sanitized)
- Used for integration testing

**Configuration**:
- NODE_ENV=staging
- LOG_LEVEL=info
- 2 pod replicas
- Auto-sync enabled

**Access**: Internal only (port-forward or minikube service)

### Production Environment

**Purpose**: Live application serving real users

**Characteristics**:
- Manual approval required for deployment
- 3 replicas for high availability
- Automatic rollback on failure
- Strict resource limits
- Enhanced monitoring and alerting

**Configuration**:
- NODE_ENV=production
- LOG_LEVEL=warn
- 3 pod replicas
- Manual sync (approval required)

**Access**: Public (via ingress or load balancer)

## Deployment Flow

### Complete Flow Diagram

```
Developer
    │
    ├─ Write Code
    ├─ Run Tests Locally
    ├─ Commit to Feature Branch
    └─ Push to GitHub
         │
         ▼
    Pull Request
         │
         ├─ CI Runs (lint, test, build)
         ├─ Code Review
         └─ Merge to Main
              │
              ▼
         CI Pipeline
              │
              ├─ Lint Code
              ├─ Run Tests
              ├─ Build Docker Image
              ├─ Push to GHCR
              └─ Tag: commit-sha, version, latest
                   │
                   ▼
         CD Staging Pipeline
                   │
                   ├─ Update Staging Manifests
                   ├─ Commit Changes
                   └─ Push to Git
                        │
                        ▼
                   ArgoCD (Staging)
                        │
                        ├─ Detect Change
                        ├─ Sync Cluster
                        ├─ Rolling Update
                        └─ Health Check ✅
                             │
                             ▼
                   Staging Deployed
                             │
                             ├─ Manual Testing
                             └─ Approval Decision
                                  │
                                  ▼
                   Manual Trigger Production
                                  │
                                  ├─ Approval Required ⏸
                                  ├─ Backup Current State
                                  ├─ Update Production Manifests
                                  └─ Commit Changes
                                       │
                                       ▼
                                  ArgoCD (Production)
                                       │
                                       ├─ Detect Change
                                       ├─ Sync Cluster
                                       ├─ Rolling Update
                                       └─ Health Check
                                            │
                                            ├─ Success ✅ → Production Deployed
                                            └─ Failure ❌ → Automatic Rollback
```

### Typical Timeline

| Stage | Duration | Trigger |
|-------|----------|---------|
| Local Development | Variable | Developer |
| CI Pipeline | ~2 minutes | Push to any branch |
| Code Review | Variable | Pull request |
| CD Staging | ~3-5 minutes | Merge to main |
| Manual Testing | Variable | Team |
| Production Approval | Variable | Manual |
| CD Production | ~5-10 minutes | Approval granted |

**Total Time (main to production)**: ~15-30 minutes (excluding approval wait time)

## Rollback Strategy

### Automatic Rollback

**Triggers**:
- Health check failures after deployment
- Pod crash loops
- Application startup failures

**Process**:
1. Health check fails after deployment
2. CD workflow detects failure
3. Previous Git commit is restored
4. ArgoCD syncs to previous version
5. Kubernetes performs rolling update back
6. Notification sent with failure details

**Duration**: ~2-3 minutes

### Manual Rollback

**When to Use**:
- Issues discovered after deployment
- Performance degradation
- User-reported bugs

**Methods**:

1. **Via Git** (Recommended):
   ```bash
   git revert <commit-sha>
   git push origin main
   # ArgoCD automatically syncs
   ```

2. **Via ArgoCD UI**:
   - Open ArgoCD UI
   - Select application
   - Click "History and Rollback"
   - Select previous version
   - Click "Rollback"

3. **Via kubectl**:
   ```bash
   kubectl rollout undo deployment/nodejs-app -n production
   ```

4. **Via ArgoCD CLI**:
   ```bash
   argocd app rollback nodejs-app-production
   ```

## Security Considerations

### Code Security

- ✅ ESLint catches common security issues
- ✅ Dependencies scanned for vulnerabilities
- ✅ No secrets in code (environment variables)
- ✅ Code review required before merge

### Container Security

- ✅ Multi-stage builds minimize attack surface
- ✅ Non-root user (UID 1001)
- ✅ Minimal base image (alpine)
- ✅ No unnecessary packages

### Deployment Security

- ✅ GHCR requires authentication
- ✅ Kubernetes RBAC for access control
- ✅ Secrets stored in Kubernetes Secrets
- ✅ Network policies for isolation
- ✅ Manual approval for production

### Pipeline Security

- ✅ GitHub Actions uses least-privilege tokens
- ✅ Secrets never logged or exposed
- ✅ Branch protection prevents direct commits
- ✅ Audit trail of all deployments

## Monitoring and Observability

### Application Monitoring

**Metrics Exposed**:
- Request count by endpoint
- Response time percentiles
- Error rates
- Active connections
- Resource usage (CPU, memory)

**Access**: `GET /metrics` (Prometheus format)

### Deployment Monitoring

**ArgoCD Dashboard**:
- Application sync status
- Health status
- Deployment history
- Resource tree view
- Event logs

**Access**: ArgoCD UI at https://localhost:8080

### Kubernetes Monitoring

**Commands**:
```bash
# View pod status
kubectl get pods -n staging

# View logs
kubectl logs -f deployment/staging-nodejs-app -n staging

# View events
kubectl get events -n staging --sort-by='.lastTimestamp'

# View resource usage
kubectl top pods -n staging
```

## Troubleshooting

### CI Pipeline Failures

**Symptom**: CI workflow fails

**Common Causes**:
- Linting errors
- Test failures
- Docker build errors
- GHCR authentication issues

**Solution**: See [GitHub Actions Documentation](github-actions.md#troubleshooting)

### Deployment Failures

**Symptom**: ArgoCD shows "OutOfSync" or "Degraded"

**Common Causes**:
- Image pull errors
- Invalid manifests
- Resource constraints
- Health check failures

**Solution**: See [Deployment Guide](deployment-guide.md#troubleshooting)

### Application Issues

**Symptom**: Application not responding or errors

**Common Causes**:
- Configuration errors
- Missing environment variables
- Resource limits too low
- Network connectivity issues

**Solution**: Check logs and events:
```bash
kubectl logs -f deployment/staging-nodejs-app -n staging
kubectl describe pod <pod-name> -n staging
```

## Best Practices

### Development

1. **Always create feature branches** - Never commit directly to main
2. **Run tests locally** - Catch issues before pushing
3. **Write meaningful commit messages** - Helps with debugging and rollbacks
4. **Keep changes small** - Easier to review and rollback if needed

### Testing

1. **Write tests for new features** - Maintain high coverage
2. **Test edge cases** - Don't just test happy paths
3. **Run full test suite** - Don't skip tests to save time
4. **Fix broken tests immediately** - Don't let them accumulate

### Deployment

1. **Test in staging first** - Never skip staging
2. **Monitor after deployment** - Watch logs and metrics
3. **Deploy during low-traffic periods** - Minimize user impact
4. **Have rollback plan ready** - Know how to revert quickly
5. **Document changes** - Update changelog and release notes

### Operations

1. **Monitor continuously** - Set up alerts for critical issues
2. **Review logs regularly** - Catch issues early
3. **Keep dependencies updated** - Security and performance
4. **Document incidents** - Learn from failures
5. **Practice rollbacks** - Be prepared for emergencies

## Related Documentation

- [GitHub Actions CI/CD](github-actions.md) - Detailed workflow documentation
- [ArgoCD Setup](argocd-setup.md) - Installation and configuration
- [Deployment Guide](deployment-guide.md) - Step-by-step deployment instructions
- [Environment Configuration](environment-configuration.md) - Configuration management

## Conclusion

This CI/CD pipeline provides a complete, production-ready deployment workflow that:

- ✅ Automates testing and deployment
- ✅ Ensures code quality through multiple checks
- ✅ Provides fast feedback to developers
- ✅ Enables safe production deployments
- ✅ Supports easy rollbacks
- ✅ Follows GitOps best practices
- ✅ Includes comprehensive monitoring

By following this architecture, you can confidently deploy changes knowing that multiple safety checks and automated processes protect your production environment.
