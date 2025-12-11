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

## API Endpoints

### Health Check
```bash
GET /health
```
Returns server status, version, uptime, and environment information.

### Users API
```bash
GET /api/users
```
Returns sample user data.

### Data API
```bash
GET /api/data
```
Returns sample data with timestamps.

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

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment (development/staging/production) | `development` |
| `LOG_LEVEL` | Logging level (debug/info/warn/error) | `info` |

See `.env.example` for complete configuration options.

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

- 📖 [Git and GitHub Setup](docs/git-github-setup.md) - Get started with version control
- 📖 [GitHub Actions CI/CD](docs/github-actions.md) - Understand the CI/CD pipeline
- 📖 [Branch Protection Setup](docs/branch-protection-setup.md) - Configure branch protection rules

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

### Server won't start
- Check if port 3000 is already in use
- Verify Node.js version (18+)
- Ensure dependencies are installed: `npm install`

### Tests failing
- Run `npm install` to ensure all dependencies are present
- Check for syntax errors: `npm run lint`
- Review test output for specific failures

### Docker build fails
- Ensure Docker is running
- Check Dockerfile syntax
- Verify all required files are present

### CI workflow not running
- Verify workflow file is in `.github/workflows/`
- Check GitHub Actions is enabled in repository settings
- Review workflow syntax for errors

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

ISC
