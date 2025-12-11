# GitHub Container Registry (GHCR) Setup Guide

## Overview

This guide explains the GitHub Container Registry integration that has been added to the CI/CD pipeline. GHCR automatically stores and versions Docker images for your application.

## What Was Implemented

### 1. GHCR Authentication
The CI workflow now authenticates with GitHub Container Registry using the built-in `GITHUB_TOKEN`:

```yaml
- name: Log in to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

### 2. Multi-Tag Strategy
Each successful build creates three image tags:

- **Commit SHA**: `ghcr.io/{owner}/{repo}:{full-commit-sha}`
  - Immutable reference to exact code version
  - Example: `ghcr.io/myuser/nodejs-cicd-pipeline:a1b2c3d4e5f6...`

- **Semantic Version**: `ghcr.io/{owner}/{repo}:v{version}`
  - Based on version in package.json
  - Example: `ghcr.io/myuser/nodejs-cicd-pipeline:v1.0.0`

- **Latest**: `ghcr.io/{owner}/{repo}:latest`
  - Only created for main branch builds
  - Example: `ghcr.io/myuser/nodejs-cicd-pipeline:latest`

### 3. Build and Push Process
The workflow:
1. Reads version from package.json
2. Builds Docker image locally
3. Tests the image (health check)
4. Pushes to GHCR with all tags
5. Verifies push succeeded

### 4. Verification Step
After pushing, the workflow logs all created tags for easy verification:

```bash
Image pushed successfully to GHCR
Image tags:
  - ghcr.io/{owner}/{repo}:{commit-sha}
  - ghcr.io/{owner}/{repo}:v1.0.0
  - ghcr.io/{owner}/{repo}:latest
```

## Prerequisites

### Enable Package Permissions

For the workflow to push images to GHCR, you need to enable write permissions:

1. Go to your repository on GitHub
2. Click **Settings** → **Actions** → **General**
3. Scroll to **Workflow permissions**
4. Select **Read and write permissions**
5. Check **Allow GitHub Actions to create and approve pull requests**
6. Click **Save**

**Important Notes:**
- The workflow has `permissions: packages: write` configured at the job level
- Images are only pushed on direct pushes to branches (not on pull requests)
- Pull requests will build and test images but skip the push step
- This prevents permission issues and unnecessary image creation for PRs

## How to Use

### Viewing Your Images

1. Go to your repository on GitHub
2. Click **Packages** in the right sidebar (or go to your profile → Packages)
3. Click on the `nodejs-cicd-pipeline` package
4. View all tags and download statistics

### Pulling Images

**Pull the latest version:**
```bash
docker pull ghcr.io/{owner}/nodejs-cicd-pipeline:latest
```

**Pull a specific version:**
```bash
docker pull ghcr.io/{owner}/nodejs-cicd-pipeline:v1.0.0
```

**Pull a specific commit:**
```bash
docker pull ghcr.io/{owner}/nodejs-cicd-pipeline:{commit-sha}
```

### Running Images

```bash
# Run the latest version
docker run -p 3000:3000 ghcr.io/{owner}/nodejs-cicd-pipeline:latest

# Test the health endpoint
curl http://localhost:3000/health
```

### Authentication for Private Repositories

If your repository is private, you need to authenticate:

```bash
# Create a Personal Access Token with read:packages scope
# Then login:
echo $GITHUB_TOKEN | docker login ghcr.io -u {username} --password-stdin

# Now you can pull private images
docker pull ghcr.io/{owner}/nodejs-cicd-pipeline:latest
```

## Workflow Integration

### When Images Are Built

Images are built and tested:
- ✅ On every push to any branch
- ✅ On every pull request

Images are pushed to GHCR:
- ✅ On direct pushes to branches (after tests pass)
- ❌ NOT on pull requests (build and test only)
- ✅ Only if lint, test, and build jobs succeed

This approach:
- Prevents permission issues with PRs from forks
- Reduces unnecessary image creation
- Still validates Docker builds work in PRs

### Image Visibility

By default:
- **Public repository** → Public images (anyone can pull)
- **Private repository** → Private images (requires authentication)

To change image visibility:
1. Go to the package page
2. Click **Package settings**
3. Change visibility in **Danger Zone** section

## Verification

### Check Workflow Logs

1. Go to **Actions** tab in your repository
2. Click on the latest workflow run
3. Click on **Build Docker Image** job
4. Expand **Build and push Docker image to GHCR** step
5. Verify you see: `pushing manifest for ghcr.io/...`

### Check Package Page

1. Go to **Packages** section
2. Verify `nodejs-cicd-pipeline` package exists
3. Check that all three tags are present:
   - Commit SHA
   - Version (v1.0.0)
   - latest

### Test Pulling Image

```bash
# Replace {owner} with your GitHub username
docker pull ghcr.io/{owner}/nodejs-cicd-pipeline:latest

# Run the image
docker run -d -p 3000:3000 --name test ghcr.io/{owner}/nodejs-cicd-pipeline:latest

# Test it works
curl http://localhost:3000/health

# Cleanup
docker stop test && docker rm test
```

## Troubleshooting

### Error: "denied: permission_denied" or "installation not allowed to Create organization package"

**Problem**: Workflow cannot push to GHCR

**Solutions**:
1. **Enable workflow permissions**:
   - Go to Settings → Actions → General
   - Enable "Read and write permissions"
   - Save and re-run the workflow

2. **Check if it's a pull request**:
   - The workflow intentionally skips GHCR push for PRs
   - This is normal behavior to prevent permission issues
   - Merge the PR or push directly to see images published

3. **For organization repositories**:
   - Go to Organization Settings → Actions → General
   - Enable "Read and write permissions" at org level
   - Or grant package permissions to the repository

4. **Verify job permissions**:
   - The workflow includes `permissions: packages: write`
   - This should be sufficient for most cases

### Error: "authentication required"

**Problem**: Cannot pull image locally

**Solution**:
1. For public repos: Check image visibility settings
2. For private repos: Authenticate with `docker login ghcr.io`
3. Use a Personal Access Token with `read:packages` scope

### Images not appearing in Packages

**Problem**: Workflow succeeds but no package visible

**Solution**:
1. Wait a few minutes for GitHub to process
2. Check workflow logs for push errors
3. Verify the build job completed successfully
4. Check you're looking at the correct repository/organization

### Wrong version tag

**Problem**: Version tag doesn't match package.json

**Solution**:
1. Verify package.json has correct version
2. Commit and push package.json changes
3. Re-run the workflow

## Requirements Satisfied

This implementation satisfies the following requirements:

- ✅ **11.6**: Uses GitHub Container Registry for artifact storage
- ✅ **13.1**: Tags images with Git commit SHA
- ✅ **13.2**: Tags images with semantic version
- ✅ **13.3**: Requires authentication for GHCR access
- ✅ **13.4**: Verifies push succeeded in workflow

## Next Steps

After GHCR is set up, you can:

1. **Set up CD workflows** (Task 8 & 9)
   - Use GHCR images for staging deployment
   - Use GHCR images for production deployment

2. **Create Kubernetes manifests** (Task 6)
   - Reference GHCR images in deployments
   - Use specific tags for version control

3. **Configure ArgoCD** (Task 7)
   - Pull images from GHCR
   - Automate deployments based on image tags

## Related Documentation

- [GitHub Actions CI/CD](github-actions.md)
- [Docker Documentation](https://docs.docker.com/)
- [GHCR Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
