# Quick Start: GitHub Container Registry

## 🚀 Quick Setup (2 minutes)

### Step 1: Enable Workflow Permissions
1. Go to your repo → **Settings** → **Actions** → **General**
2. Under "Workflow permissions", select **Read and write permissions**
3. Click **Save**

### Step 2: Push Code
```bash
git add .
git commit -m "Add GHCR integration"
git push origin main
```

**Note**: Push directly to a branch (not via PR) for images to be published.

### Step 3: Verify
1. Go to **Actions** tab
2. Wait for workflow to complete (green checkmark)
3. Go to **Packages** (right sidebar or your profile)
4. See your `nodejs-cicd-pipeline` package with 3 tags

**If no package appears**: Check workflow permissions (Step 1) and ensure you pushed directly to a branch (not a PR).

## 🎯 Quick Test

Pull and run your image:
```bash
# Replace {owner} with your GitHub username
docker pull ghcr.io/{owner}/nodejs-cicd-pipeline:latest
docker run -p 3000:3000 ghcr.io/{owner}/nodejs-cicd-pipeline:latest
```

Test it works:
```bash
curl http://localhost:3000/health
```

## 📦 Available Tags

After each successful build, you get:

| Tag | Example | Use Case |
|-----|---------|----------|
| `{commit-sha}` | `a1b2c3d4e5f6...` | Exact version, rollbacks |
| `v{version}` | `v1.0.0` | Release management |
| `latest` | `latest` | Development, testing |

## ✅ What's Included

- ✅ Automatic authentication with GHCR
- ✅ Multi-tag strategy (commit SHA, version, latest)
- ✅ Multi-platform support (amd64 + arm64)
- ✅ Build verification before push
- ✅ Push verification after upload
- ✅ Integration with existing CI pipeline
- ✅ Works on Apple Silicon Macs, Intel/AMD, and ARM servers

## 🔍 Troubleshooting

**Workflow fails with "permission denied"**
→ Enable write permissions (Step 1 above)
→ Ensure you're pushing directly to a branch (not a PR)

**No package appears after successful workflow**
→ Check if it was a pull request (PRs skip GHCR push)
→ Push directly to main or another branch

**Can't pull image**
→ Check image visibility in Package settings
→ Authenticate for private repos: `docker login ghcr.io`

**Wrong version tag**
→ Update version in package.json and push

## 📚 Full Documentation

See [GHCR-SETUP.md](GHCR-SETUP.md) for complete details.
