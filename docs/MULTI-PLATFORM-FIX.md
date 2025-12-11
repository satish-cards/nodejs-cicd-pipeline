# Multi-Platform Docker Images Fix

## Issue Encountered

When trying to pull the image on Apple Silicon Mac (M1/M2/M3):
```
Error: no matching manifest for linux/arm64/v8 in the manifest list entries
```

## Root Cause

The initial workflow only built images for `linux/amd64` (Intel/AMD processors). Apple Silicon Macs use ARM64 architecture, so they couldn't run the amd64-only images.

## Solution Implemented

### Updated Workflow to Build Multi-Platform Images

**Before:**
```yaml
- name: Build and push Docker image to GHCR
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: |
      ghcr.io/${{ github.repository }}:${{ github.sha }}
      ghcr.io/${{ github.repository }}:v1.0.0
      ghcr.io/${{ github.repository }}:latest
```

**After:**
```yaml
- name: Build and push multi-platform Docker image to GHCR
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    platforms: linux/amd64,linux/arm64  # ← Added multi-platform support
    tags: |
      ghcr.io/${{ github.repository }}:${{ github.sha }}
      ghcr.io/${{ github.repository }}:v1.0.0
      ghcr.io/${{ github.repository }}:latest
```

### Key Changes

1. **Added `platforms` parameter** to the push step:
   - `linux/amd64`: Intel/AMD processors
   - `linux/arm64`: ARM processors (Apple Silicon, AWS Graviton)

2. **Kept test build as amd64-only**:
   - Testing step still uses `linux/amd64` only (faster)
   - Multi-platform build happens only for the push step

3. **Updated verification message**:
   - Now shows "Multi-platform image pushed successfully"
   - Lists both platforms

## Supported Platforms

After this fix, images work on:

| Platform | Architecture | Examples |
|----------|-------------|----------|
| ✅ Intel/AMD PCs | linux/amd64 | Most laptops, desktops, cloud VMs |
| ✅ Apple Silicon | linux/arm64 | M1, M2, M3 Macs |
| ✅ AWS Graviton | linux/arm64 | ARM-based cloud instances |
| ✅ Raspberry Pi | linux/arm64 | Pi 4, Pi 5 (64-bit OS) |
| ✅ Most cloud providers | linux/amd64 | GCP, Azure, DigitalOcean |

## How It Works

Docker Buildx (enabled by `docker/setup-buildx-action`) uses QEMU emulation to build images for different architectures:

1. **Build for amd64**: Native build on GitHub's amd64 runners
2. **Build for arm64**: Emulated build using QEMU
3. **Create manifest**: Docker creates a multi-arch manifest
4. **Push both**: Both images pushed with same tags
5. **Auto-select**: Docker automatically pulls the right architecture

## Performance Impact

**Build time increase**: ~30-60 seconds
- Building for two platforms takes longer
- Emulated ARM64 build is slower than native
- Still completes in ~3-4 minutes total

**Image size**: No change
- Each platform has its own image
- Docker only pulls the one you need
- No extra storage on your machine

## Verification

### Check Multi-Platform Support

```bash
# Inspect the manifest
docker manifest inspect ghcr.io/satish-cards/nodejs-cicd-pipeline:latest

# Look for both platforms in output:
# "platform": {
#   "architecture": "amd64",
#   "os": "linux"
# }
# and
# "platform": {
#   "architecture": "arm64",
#   "os": "linux"
# }
```

### Test on Different Platforms

**On Apple Silicon Mac:**
```bash
docker pull ghcr.io/satish-cards/nodejs-cicd-pipeline:latest
# Should pull arm64 version automatically
docker run -p 3000:3000 ghcr.io/satish-cards/nodejs-cicd-pipeline:latest
```

**On Intel/AMD:**
```bash
docker pull ghcr.io/satish-cards/nodejs-cicd-pipeline:latest
# Should pull amd64 version automatically
docker run -p 3000:3000 ghcr.io/satish-cards/nodejs-cicd-pipeline:latest
```

**Force specific platform:**
```bash
# Force ARM64 (even on Intel Mac with Rosetta)
docker pull --platform linux/arm64 ghcr.io/satish-cards/nodejs-cicd-pipeline:latest

# Force AMD64 (even on Apple Silicon)
docker pull --platform linux/amd64 ghcr.io/satish-cards/nodejs-cicd-pipeline:latest
```

## Next Steps

After pushing the updated workflow:

1. **Wait for workflow to complete** (~3-4 minutes)
2. **Pull the new image**:
   ```bash
   docker pull ghcr.io/satish-cards/nodejs-cicd-pipeline:latest
   ```
3. **Verify it works on your Mac**:
   ```bash
   docker run -p 3000:3000 ghcr.io/satish-cards/nodejs-cicd-pipeline:latest
   curl http://localhost:3000/health
   ```

## Benefits

✅ **Universal compatibility**: Works on any modern platform
✅ **No manual intervention**: Docker picks the right architecture
✅ **Future-proof**: Ready for ARM-based cloud instances
✅ **Developer-friendly**: Works on Apple Silicon Macs
✅ **Production-ready**: Supports both x86 and ARM servers

## Related Documentation

- [GHCR Setup Guide](GHCR-SETUP.md)
- [Quick Start Guide](QUICK-START-GHCR.md)
- [Docker Buildx Documentation](https://docs.docker.com/build/building/multi-platform/)
