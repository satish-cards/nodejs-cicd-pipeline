# Node.js CI/CD Pipeline Demo

A complete CI/CD pipeline demonstration project featuring a Node.js/Express application with automated testing, containerization, and GitOps deployment.

## Features

- ✅ Express.js REST API with health checks
- ✅ Automated testing with Jest
- ✅ Code quality checks with ESLint
- ✅ Docker containerization
- ✅ GitHub Actions CI/CD pipeline
- ✅ Kubernetes deployment manifests
- ✅ ArgoCD GitOps integration
- ✅ Environment-specific configuration

## Project Structure

```
.
├── src/                    # Application source code
│   ├── routes/            # API route handlers
│   ├── middleware/        # Express middleware
│   └── config/            # Configuration management
├── tests/                  # Test files
├── k8s/                    # Kubernetes manifests
│   ├── base/              # Base Kubernetes resources
│   ├── overlays/          # Environment-specific overlays
│   └── argocd/            # ArgoCD application definitions
├── .github/                # GitHub Actions workflows
│   └── workflows/         # CI/CD workflow definitions
├── docs/                   # Documentation
├── package.json            # Node.js dependencies
├── .eslintrc.json         # ESLint configuration
├── jest.config.js         # Jest test configuration
└── Dockerfile             # Docker image definition
```

## Quick Start

### Prerequisites

- Node.js 18+
- npm
- Git
- Docker (optional, for containerization)
- GitHub account (for CI/CD)

### Local Development Setup

1. **Clone the repository** (or initialize if starting fresh)
   ```bash
   git clone https://github.com/YOUR_USERNAME/nodejs-cicd-pipeline.git
   cd nodejs-cicd-pipeline
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Create environment file**
   ```bash
   cp .env.example .env
   ```

4. **Start development server**
   ```bash
   npm run dev
   ```

5. **Verify the server is running**
   ```bash
   curl http://localhost:3000/health
   ```

### Setting Up Git and GitHub

If you haven't set up Git and GitHub yet, follow the comprehensive guide:

📖 **[Git and GitHub Setup Guide](docs/git-github-setup.md)**

This guide covers:
- Initializing Git repository
- Creating GitHub repository
- Connecting local and remote repositories
- Setting up authentication
- First commit and push

### Setting Up CI/CD Pipeline

Once your code is on GitHub, the CI/CD pipeline will automatically run. To configure it properly:

1. **Verify CI workflow runs**
   - Push code to GitHub
   - Go to Actions tab in your repository
   - Watch the CI Pipeline workflow execute

2. **Set up branch protection** (recommended)
   - Follow the [Branch Protection Setup Guide](docs/branch-protection-setup.md)
   - Require CI checks to pass before merging
   - Require pull request reviews

3. **Learn about the CI workflow**
   - Read the [GitHub Actions Documentation](docs/github-actions.md)
   - Understand each job and its purpose

## Available Scripts

- `npm start` - Start the production server
- `npm run dev` - Start the development server
- `npm test` - Run tests with coverage
- `npm run test:watch` - Run tests in watch mode
- `npm run lint` - Run ESLint code quality checks

## API Documentation

### Health Check Endpoint

**Endpoint**: `GET /health`

**Description**: Returns the operational status and metadata of the application server.

**Response**:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "version": "1.0.0",
  "uptime": 120,
  "environment": "development"
}
```

**Status Codes**:
- `200 OK` - Server is healthy and operational

**Use Cases**:
- Kubernetes liveness and readiness probes
- Monitoring and health checks
- Deployment verification

**Example**:
```bash
curl http://localhost:3000/health
```

---

### Users API Endpoint

**Endpoint**: `GET /api/users`

**Description**: Returns a list of sample user data.

**Response**:
```json
{
  "users": [
    {
      "id": "1",
      "name": "John Doe",
      "email": "john@example.com",
      "createdAt": "2024-01-15T10:00:00.000Z"
    },
    {
      "id": "2",
      "name": "Jane Smith",
      "email": "jane@example.com",
      "createdAt": "2024-01-15T10:05:00.000Z"
    }
  ],
  "count": 2
}
```

**Status Codes**:
- `200 OK` - Successfully retrieved users
- `500 Internal Server Error` - Server error occurred

**Example**:
```bash
curl http://localhost:3000/api/users
```

---

### Data API Endpoint

**Endpoint**: `GET /api/data`

**Description**: Returns sample data with timestamps and metadata.

**Response**:
```json
{
  "data": [
    {
      "id": "1",
      "value": "Sample data 1",
      "timestamp": "2024-01-15T10:30:00.000Z",
      "metadata": {
        "source": "api",
        "type": "sample"
      }
    },
    {
      "id": "2",
      "value": "Sample data 2",
      "timestamp": "2024-01-15T10:31:00.000Z",
      "metadata": {
        "source": "api",
        "type": "sample"
      }
    }
  ],
  "count": 2
}
```

**Status Codes**:
- `200 OK` - Successfully retrieved data
- `500 Internal Server Error` - Server error occurred

**Example**:
```bash
curl http://localhost:3000/api/data
```

---

### Metrics Endpoint

**Endpoint**: `GET /metrics`

**Description**: Returns application metrics in Prometheus format for monitoring.

**Response**: Plain text in Prometheus exposition format

**Metrics Exposed**:
- `http_requests_total` - Total number of HTTP requests
- `http_request_duration_seconds` - HTTP request duration histogram
- `http_requests_in_progress` - Number of HTTP requests currently in progress

**Example**:
```bash
curl http://localhost:3000/metrics
```

**Use Cases**:
- Prometheus scraping
- Performance monitoring
- Alerting based on metrics

## Testing

Run the test suite:
```bash
npm test
```

Run tests in watch mode during development:
```bash
npm run test:watch
```

## Docker

### Build Docker Image
```bash
docker build -t nodejs-cicd-pipeline .
```

### Run Docker Container
```bash
docker run -p 3000:3000 -e NODE_ENV=production nodejs-cicd-pipeline
```

### Test Docker Container
```bash
# Start container
docker run -d --name test-app -p 3000:3000 nodejs-cicd-pipeline

# Test health endpoint
curl http://localhost:3000/health

# Stop and remove container
docker stop test-app
docker rm test-app
```

## Environment Variables

### Server Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `PORT` | Server port number | `3000` | No |
| `HOST` | Server host address | `0.0.0.0` | No |
| `NODE_ENV` | Environment mode | `development` | No |

**Valid NODE_ENV values**: `development`, `staging`, `production`

### Logging Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `LOG_LEVEL` | Logging verbosity level | `info` | No |

**Valid LOG_LEVEL values**: `debug`, `info`, `warn`, `error`

**Log Behavior by Environment**:
- `development`: Human-readable text format, debug level
- `staging`: JSON format, info level
- `production`: JSON format, warn level

### Application Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `APP_VERSION` | Application version | `1.0.0` | No |

### Feature Flags

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `ENABLE_METRICS` | Enable /metrics endpoint | `true` | No |
| `ENABLE_DETAILED_ERRORS` | Show detailed error messages | `true` | No |

**Note**: In production, `ENABLE_DETAILED_ERRORS` should be set to `false` to avoid exposing sensitive information.

### Configuration File

See `.env.example` for a complete template with all available configuration options:

```bash
cp .env.example .env
# Edit .env with your values
```

### Environment-Specific Configuration

**Development**:
```bash
NODE_ENV=development
LOG_LEVEL=debug
ENABLE_DETAILED_ERRORS=true
```

**Staging**:
```bash
NODE_ENV=staging
LOG_LEVEL=info
ENABLE_DETAILED_ERRORS=true
```

**Production**:
```bash
NODE_ENV=production
LOG_LEVEL=warn
ENABLE_DETAILED_ERRORS=false
```

## CI/CD Pipeline

The project includes a complete CI/CD pipeline using GitHub Actions:

### Continuous Integration (CI)
Runs on every push and pull request:
1. ✅ Install dependencies with integrity check
2. ✅ Run ESLint for code quality
3. ✅ Execute test suite with coverage
4. ✅ Build and test Docker image
5. ✅ Push to GitHub Container Registry (GHCR)
6. ✅ Verify health checks

### Container Registry
Docker images are automatically published to GitHub Container Registry with multiple tags:
- `ghcr.io/{owner}/{repo}:{commit-sha}` - Specific commit version
- `ghcr.io/{owner}/{repo}:v{version}` - Semantic version
- `ghcr.io/{owner}/{repo}:latest` - Latest build (main branch)

Pull an image:
```bash
docker pull ghcr.io/{owner}/nodejs-cicd-pipeline:latest
```

### Continuous Deployment (CD)
- **Staging**: Automatic deployment on merge to `main`
- **Production**: Manual approval required

See [GitHub Actions Documentation](docs/github-actions.md) for details.

## Kubernetes and ArgoCD Deployment

### 🚀 Quick Setup (3 Commands)

Set up a complete local Kubernetes cluster with ArgoCD for GitOps deployments:

```bash
# 1. Set up Kubernetes cluster and ArgoCD
./setup-k8s-argocd.sh

# 2. Configure GHCR image pull secrets
./setup-ghcr-secrets.sh

# 3. Deploy applications
kubectl apply -f k8s/argocd/staging-app.yaml
```

**Time:** ~5-10 minutes total

### Prerequisites

- Docker Desktop running
- kubectl installed (`brew install kubectl`)
- minikube installed (`brew install minikube`)
- GitHub Personal Access Token with `read:packages` permission

### What You Get

- ✅ Local Kubernetes cluster (Minikube)
- ✅ ArgoCD for GitOps deployments
- ✅ Staging and Production namespaces
- ✅ Automated deployments from Git
- ✅ Complete CI/CD pipeline integration

### Complete Setup Guide

📖 **[Kubernetes & ArgoCD Quick Start](docs/QUICK-START-K8S.md)** - Step-by-step guide

📖 **[Detailed Setup Guide](docs/kubernetes-argocd-setup.md)** - Manual setup instructions

📖 **[Setup Summary](K8S-SETUP-SUMMARY.md)** - Overview and quick reference

### Check Status

```bash
./check-k8s-status.sh
```

This shows:
- Cluster status
- ArgoCD credentials
- Application pods
- Services
- Quick access commands

### Access Your Application

```bash
# Option 1: Minikube service (easiest)
minikube service staging-nodejs-app -n staging

# Option 2: Port forward
kubectl port-forward svc/staging-nodejs-app -n staging 3000:3000

# Option 3: Get URL
minikube service staging-nodejs-app -n staging --url
```

### Complete CI/CD Flow

Once set up, pushing to `main` branch triggers:

1. **GitHub Actions CI** - Lint, test, build Docker image
2. **GitHub Actions CD** - Push image, update manifests
3. **ArgoCD** - Automatically syncs and deploys to Kubernetes
4. **Kubernetes** - Rolling update with zero downtime

### Useful Commands

```bash
# View all resources
kubectl get all -n staging

# View logs
kubectl logs -f deployment/staging-nodejs-app -n staging

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Then open: https://localhost:8080

# Restart deployment
kubectl rollout restart deployment/staging-nodejs-app -n staging

# Rollback
kubectl rollout undo deployment/staging-nodejs-app -n staging
```

## Documentation

### Getting Started
- 📖 [Git and GitHub Setup](docs/git-github-setup.md) - Get started with version control
- 📖 [Branch Protection Setup](docs/branch-protection-setup.md) - Configure branch protection rules

### CI/CD Pipeline
- 📖 [CI/CD Overview](docs/ci-cd-overview.md) - Complete pipeline architecture and flow
- 📖 [GitHub Actions CI/CD](docs/github-actions.md) - Detailed workflow documentation
- 📖 [Deployment Guide](docs/deployment-guide.md) - Step-by-step deployment instructions

### Kubernetes and GitOps
- 📖 [Kubernetes & ArgoCD Quick Start](docs/QUICK-START-K8S.md) - Fast setup guide
- 📖 [Kubernetes & ArgoCD Setup](docs/kubernetes-argocd-setup.md) - Detailed installation guide
- 📖 [ArgoCD Setup](docs/argocd-setup.md) - ArgoCD configuration

### Configuration
- 📖 [Environment Configuration](docs/environment-configuration.md) - Configuration management
- 📖 [Secrets Management](k8s/SECRETS-MANAGEMENT.md) - Handling sensitive data

## Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/my-new-feature
   ```

2. **Make changes and test locally**
   ```bash
   npm run lint
   npm test
   ```

3. **Commit and push**
   ```bash
   git add .
   git commit -m "Add new feature"
   git push origin feature/my-new-feature
   ```

4. **Create Pull Request**
   - Go to GitHub repository
   - Click "New Pull Request"
   - CI will run automatically
   - Merge after CI passes and review approval

## Troubleshooting

### Local Development Issues

#### Server won't start

**Symptoms**:
- Error: "Port 3000 is already in use"
- Server crashes on startup
- No response from server

**Solutions**:
```bash
# Check if port is in use
lsof -i :3000

# Kill process using port 3000
kill -9 $(lsof -t -i:3000)

# Or use a different port
PORT=3001 npm start

# Verify Node.js version
node --version  # Should be 18+

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

#### Tests failing

**Symptoms**:
- Test suite fails
- Coverage below threshold
- Timeout errors

**Solutions**:
```bash
# Ensure all dependencies are installed
npm install

# Run linting to check for syntax errors
npm run lint

# Run tests with verbose output
npm test -- --verbose

# Run specific test file
npm test -- tests/health.test.js

# Clear Jest cache
npm test -- --clearCache
```

#### Linting errors

**Symptoms**:
- ESLint reports errors
- CI pipeline fails on lint step

**Solutions**:
```bash
# Check linting errors
npm run lint

# Auto-fix some errors
npm run lint -- --fix

# Check specific file
npx eslint src/server.js
```

### Docker Issues

#### Docker build fails

**Symptoms**:
- Build errors during `docker build`
- Missing files or dependencies
- Permission errors

**Solutions**:
```bash
# Ensure Docker is running
docker info

# Check Dockerfile syntax
docker build --no-cache -t test .

# Verify .dockerignore isn't excluding needed files
cat .dockerignore

# Build with verbose output
docker build --progress=plain -t test .
```

#### Container won't start

**Symptoms**:
- Container exits immediately
- Health check fails
- Application errors in logs

**Solutions**:
```bash
# Check container logs
docker logs <container-id>

# Run container interactively
docker run -it nodejs-cicd-pipeline sh

# Check environment variables
docker run nodejs-cicd-pipeline env

# Test with different port
docker run -p 3001:3000 -e PORT=3000 nodejs-cicd-pipeline
```

### CI/CD Issues

#### CI workflow not running

**Symptoms**:
- No workflow runs appear in Actions tab
- Workflow doesn't trigger on push

**Solutions**:
1. Verify workflow file location: `.github/workflows/ci.yml`
2. Check YAML syntax: Use a YAML validator
3. Ensure GitHub Actions is enabled:
   - Go to Settings → Actions → General
   - Enable "Allow all actions and reusable workflows"
4. Check branch name matches trigger pattern
5. Force trigger: Make a small change and push again

#### CI pipeline fails

**Symptoms**:
- Lint job fails
- Test job fails
- Build job fails

**Solutions**:

**For lint failures**:
```bash
# Run locally first
npm run lint
npm run lint -- --fix
git add .
git commit -m "Fix linting errors"
git push
```

**For test failures**:
```bash
# Run tests locally
npm test

# Check for environment differences
NODE_ENV=test npm test

# Review test logs in GitHub Actions
```

**For build failures**:
```bash
# Test Docker build locally
docker build -t test .

# Check for missing files
git status
git add <missing-files>
```

#### Image push to GHCR fails

**Symptoms**:
- Authentication errors
- Permission denied
- Image not appearing in packages

**Solutions**:
1. Check repository settings:
   - Settings → Actions → General
   - Workflow permissions: "Read and write permissions"
2. Verify GITHUB_TOKEN has correct permissions
3. Check package visibility settings
4. Wait a few minutes and retry

### Kubernetes Issues

#### Pods not starting

**Symptoms**:
- Pods stuck in "Pending" or "ImagePullBackOff"
- CrashLoopBackOff status

**Solutions**:
```bash
# Check pod status
kubectl get pods -n staging

# Describe pod for details
kubectl describe pod <pod-name> -n staging

# Check logs
kubectl logs <pod-name> -n staging

# Check events
kubectl get events -n staging --sort-by='.lastTimestamp'
```

**Common causes**:
- Image pull errors: Check image pull secret
- Resource constraints: Check node resources
- Configuration errors: Check ConfigMap and environment variables
- Health check failures: Check application logs

#### Image pull errors

**Symptoms**:
- "ImagePullBackOff" or "ErrImagePull"
- Authentication errors

**Solutions**:
```bash
# Verify image exists in GHCR
# Check GitHub → Packages

# Recreate image pull secret
kubectl delete secret ghcr-secret -n staging
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USERNAME \
  --docker-password=$GITHUB_TOKEN \
  -n staging

# Verify secret is referenced in deployment
kubectl get deployment staging-nodejs-app -n staging -o yaml | grep imagePullSecrets
```

#### Service not accessible

**Symptoms**:
- Cannot access application
- Connection refused
- Timeout errors

**Solutions**:
```bash
# Check service exists
kubectl get svc -n staging

# Check service endpoints
kubectl get endpoints -n staging

# Port forward to test
kubectl port-forward svc/staging-nodejs-app -n staging 3000:3000

# For Minikube, use service URL
minikube service staging-nodejs-app -n staging --url
```

### ArgoCD Issues

#### Application out of sync

**Symptoms**:
- ArgoCD shows "OutOfSync"
- Changes not deploying

**Solutions**:
```bash
# Check application status
argocd app get nodejs-app-staging

# View differences
argocd app diff nodejs-app-staging

# Force sync
argocd app sync nodejs-app-staging

# Hard refresh
argocd app get nodejs-app-staging --hard-refresh
```

#### ArgoCD UI not accessible

**Symptoms**:
- Cannot access ArgoCD UI
- Connection refused

**Solutions**:
```bash
# Check ArgoCD pods are running
kubectl get pods -n argocd

# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### Common Error Messages

#### "EADDRINUSE: address already in use"

**Cause**: Port 3000 is already in use

**Solution**:
```bash
# Find and kill process
lsof -i :3000
kill -9 <PID>

# Or use different port
PORT=3001 npm start
```

#### "Cannot find module"

**Cause**: Missing dependencies

**Solution**:
```bash
npm install
```

#### "Permission denied"

**Cause**: File permission issues

**Solution**:
```bash
# Fix file permissions
chmod +x <file>

# For Docker
sudo usermod -aG docker $USER
# Then log out and back in
```

#### "Context deadline exceeded"

**Cause**: Kubernetes operation timeout

**Solution**:
```bash
# Increase timeout
kubectl wait --for=condition=Ready pods --all -n staging --timeout=600s

# Check what's blocking
kubectl get events -n staging
```

### Getting Help

If you're still stuck:

1. **Check logs**: Application, Docker, Kubernetes, ArgoCD
2. **Review documentation**: See links in [Documentation](#documentation) section
3. **Search issues**: Check GitHub issues for similar problems
4. **Ask for help**: Create a new issue with:
   - Description of the problem
   - Steps to reproduce
   - Error messages and logs
   - Environment details (OS, versions, etc.)

### Useful Debugging Commands

```bash
# Application
npm run lint
npm test
npm start

# Docker
docker ps
docker logs <container-id>
docker exec -it <container-id> sh

# Kubernetes
kubectl get all -n staging
kubectl describe pod <pod-name> -n staging
kubectl logs -f <pod-name> -n staging
kubectl get events -n staging

# ArgoCD
argocd app list
argocd app get <app-name>
argocd app sync <app-name>
argocd app logs <app-name>
```

For more detailed troubleshooting, see the [Deployment Guide](docs/deployment-guide.md#troubleshooting)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

ISC
