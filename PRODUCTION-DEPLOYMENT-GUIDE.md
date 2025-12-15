# Production Deployment Guide

## Where to Get the Image Tag

### ✅ Recommended: Use Commit SHA from Staging

**Best Practice:** Always promote the exact image that's running in staging after you've tested it.

```bash
# Get the current staging image tag
kubectl get deployment -n staging staging-nodejs-app -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Example output:**
```
ghcr.io/satish-cards/nodejs-cicd-pipeline:541eb6c2bc11fc9ffad55b02ab0fbb18756ac53a
```

The tag is: `541eb6c2bc11fc9ffad55b02ab0fbb18756ac53a` (commit SHA)

---

## Available Image Tag Options

### 1. Commit SHA (Recommended) ✅

**Format:** `<40-character-git-commit-sha>`

**Example:** `541eb6c2bc11fc9ffad55b02ab0fbb18756ac53a`

**Pros:**
- ✅ Immutable - never changes
- ✅ Exact version you tested in staging
- ✅ Easy to trace back to code changes
- ✅ Can see exactly what code is deployed

**Cons:**
- ❌ Not human-readable
- ❌ Hard to remember

**When to use:** Always for production deployments

---

### 2. Semantic Version

**Format:** `v<major>.<minor>.<patch>`

**Example:** `v1.0.0`

**Pros:**
- ✅ Human-readable
- ✅ Follows semantic versioning
- ✅ Easy to communicate

**Cons:**
- ❌ Points to the same image as commit SHA
- ❌ Less precise for troubleshooting

**When to use:** For release announcements, documentation

---

### 3. Latest Tag ❌

**Format:** `latest`

**Pros:**
- ✅ Always points to newest build

**Cons:**
- ❌ Can change unexpectedly
- ❌ No version control
- ❌ Hard to rollback
- ❌ Not recommended for production

**When to use:** Never in production, only for local development

---

## Deployment Workflow

### Step 1: Test in Staging

```bash
# Check staging is healthy
kubectl get pods -n staging

# Test staging endpoints
MINIKUBE_IP=$(minikube ip)
STAGING_PORT=$(kubectl get svc -n staging staging-nodejs-app -o jsonpath='{.spec.ports[0].nodePort}')

curl http://$MINIKUBE_IP:$STAGING_PORT/health
curl http://$MINIKUBE_IP:$STAGING_PORT/api/users
```

### Step 2: Get Staging Image Tag

```bash
# Get the exact image tag running in staging
STAGING_TAG=$(kubectl get deployment -n staging staging-nodejs-app -o jsonpath='{.spec.template.spec.containers[0].image}' | cut -d':' -f2)

echo "Staging is running: $STAGING_TAG"
```

### Step 3: Update Production Kustomization

**Option A: Use the helper script (Recommended)**

```bash
./promote-to-production.sh
```

**Option B: Manual update**

Edit `k8s/overlays/production/kustomization.yaml`:

```yaml
images:
  - name: ghcr.io/GITHUB_USERNAME/nodejs-cicd-pipeline
    newName: ghcr.io/satish-cards/nodejs-cicd-pipeline
    newTag: 541eb6c2bc11fc9ffad55b02ab0fbb18756ac53a  # ← Update this
```

### Step 4: Commit and Push

```bash
git add k8s/overlays/production/kustomization.yaml
git commit -m "Deploy to production: 541eb6c2bc11fc9ffad55b02ab0fbb18756ac53a"
git push origin main
```

### Step 5: Sync in ArgoCD

**Option A: ArgoCD UI**
1. Open https://localhost:8080
2. Login (admin / 2wUswanu6c-nIXmi)
3. Click on `nodejs-app-production`
4. Click **SYNC** button
5. Click **SYNCHRONIZE**

**Option B: ArgoCD CLI**

```bash
argocd app sync nodejs-app-production
```

### Step 6: Monitor Deployment

```bash
# Watch pods rolling out
kubectl get pods -n production -w

# Check deployment status
kubectl rollout status deployment/production-nodejs-app -n production

# Verify health
PRODUCTION_PORT=$(kubectl get svc -n production production-nodejs-app -o jsonpath='{.spec.ports[0].nodePort}')
curl http://$(minikube ip):$PRODUCTION_PORT/health
```

---

## Quick Reference

### Find Image Tags

```bash
# Current staging tag
kubectl get deployment -n staging staging-nodejs-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Current production tag
kubectl get deployment -n production production-nodejs-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# All available tags in GHCR (requires GitHub CLI)
gh api /user/packages/container/nodejs-cicd-pipeline/versions | jq -r '.[].metadata.container.tags[]'
```

### Rollback Production

If something goes wrong, rollback to the previous image:

```bash
# Get previous production tag from git history
git log --oneline k8s/overlays/production/kustomization.yaml

# Revert to previous commit
git revert HEAD
git push origin main

# Sync in ArgoCD
argocd app sync nodejs-app-production
```

---

## Example: Complete Deployment

```bash
# 1. Check staging is healthy
$ kubectl get pods -n staging
NAME                                  READY   STATUS    RESTARTS   AGE
staging-nodejs-app-679d97dc75-p5qhn   1/1     Running   0          10m
staging-nodejs-app-679d97dc75-xqv7k   1/1     Running   0          10m

# 2. Get staging image tag
$ kubectl get deployment -n staging staging-nodejs-app -o jsonpath='{.spec.template.spec.containers[0].image}'
ghcr.io/satish-cards/nodejs-cicd-pipeline:541eb6c2bc11fc9ffad55b02ab0fbb18756ac53a

# 3. Use the helper script
$ ./promote-to-production.sh

🚀 Production Deployment Helper
================================

📦 Current Staging Deployment:
   Image: ghcr.io/satish-cards/nodejs-cicd-pipeline:541eb6c2bc11fc9ffad55b02ab0fbb18756ac53a
   Tag: 541eb6c2bc11fc9ffad55b02ab0fbb18756ac53a

🏭 Current Production Deployment:
   Image: ghcr.io/satish-cards/nodejs-cicd-pipeline:949508d3e2da5361137f926e7174a0b3032089bb
   Tag: 949508d3e2da5361137f926e7174a0b3032089bb

Do you want to promote staging (541eb6c2bc11fc9ffad55b02ab0fbb18756ac53a) to production? (yes/no): yes

✅ Updated k8s/overlays/production/kustomization.yaml
✅ Changes pushed to repository

🔧 Next Steps:
   1. ArgoCD will detect the changes
   2. Manually sync: argocd app sync nodejs-app-production
   3. Monitor: kubectl get pods -n production -w

🎉 Production deployment initiated!
```

---

## Troubleshooting

### ArgoCD shows "OutOfSync"

This is normal after pushing changes. You need to manually sync:

```bash
argocd app sync nodejs-app-production
```

### Pods not updating

Check if ArgoCD synced successfully:

```bash
kubectl get application nodejs-app-production -n argocd
```

### Image pull errors

Verify the image exists in GHCR:

```bash
docker pull ghcr.io/satish-cards/nodejs-cicd-pipeline:541eb6c2bc11fc9ffad55b02ab0fbb18756ac53a
```

---

## Best Practices

1. ✅ **Always test in staging first**
2. ✅ **Use commit SHA tags for production**
3. ✅ **Document what you're deploying** (git commit message)
4. ✅ **Monitor the deployment** (watch pods, check health)
5. ✅ **Have a rollback plan** (know the previous tag)
6. ❌ **Never use `latest` tag in production**
7. ❌ **Never skip staging testing**
8. ❌ **Never deploy directly to production without ArgoCD**

---

## Summary

**To deploy to production:**

1. Get the staging image tag (commit SHA)
2. Update `k8s/overlays/production/kustomization.yaml`
3. Commit and push
4. Sync in ArgoCD (manual approval)
5. Monitor and verify

**Use the helper script for convenience:**
```bash
./promote-to-production.sh
```
