# GHCR Permissions Fix

## Issue Encountered

The initial workflow failed with:
```
ERROR: denied: installation not allowed to Create organization package
```

## Root Cause

The `GITHUB_TOKEN` provided by GitHub Actions needs explicit permissions to push packages to GHCR. Additionally, pull requests from forks have restricted permissions for security reasons.

## Solution Implemented

### 1. Added Job-Level Permissions

```yaml
build:
  name: Build Docker Image
  runs-on: ubuntu-latest
  needs: [lint, test]
  permissions:
    contents: read
    packages: write  # ← Added this
```

This explicitly grants the build job permission to write packages to GHCR.

### 2. Made GHCR Push Conditional

```yaml
- name: Build and push Docker image to GHCR
  if: github.event_name != 'pull_request'  # ← Only push on direct pushes
  uses: docker/build-push-action@v5
  with:
    push: true
```

**Why?**
- Pull requests (especially from forks) have restricted permissions
- Building and testing Docker images in PRs is valuable
- Pushing images for every PR is unnecessary
- This prevents permission errors and reduces image clutter

### 3. Added Skip Message for PRs

```yaml
- name: Skip GHCR push (Pull Request)
  if: github.event_name == 'pull_request'
  run: |
    echo "Skipping GHCR push for pull request"
    echo "Images are only pushed on direct pushes to branches"
```

This provides clear feedback when the push is intentionally skipped.

## Workflow Behavior

### On Pull Requests
1. ✅ Install dependencies
2. ✅ Run linting
3. ✅ Run tests
4. ✅ Build Docker image
5. ✅ Test Docker image
6. ⏭️ Skip GHCR push
7. ✅ Status check

### On Direct Push (to any branch)
1. ✅ Install dependencies
2. ✅ Run linting
3. ✅ Run tests
4. ✅ Build Docker image
5. ✅ Test Docker image
6. ✅ Push to GHCR
7. ✅ Verify push
8. ✅ Status check

## Required Setup

Users still need to enable workflow permissions:

1. Go to repository **Settings** → **Actions** → **General**
2. Under "Workflow permissions", select **Read and write permissions**
3. Click **Save**

This is a one-time setup per repository.

## Benefits

✅ **Security**: PRs from forks can't push images
✅ **Efficiency**: Fewer unnecessary images created
✅ **Reliability**: No permission errors on PRs
✅ **Clarity**: Clear messaging about when images are pushed
✅ **Flexibility**: Still validates Docker builds in PRs

## Testing

To test the fix:

1. **Create a PR**: Should build and test, but skip push
2. **Push to branch**: Should build, test, and push to GHCR
3. **Check packages**: Images should appear after direct push

## Related Documentation

- [GHCR Setup Guide](GHCR-SETUP.md)
- [Quick Start Guide](QUICK-START-GHCR.md)
- [GitHub Actions Docs](github-actions.md)
