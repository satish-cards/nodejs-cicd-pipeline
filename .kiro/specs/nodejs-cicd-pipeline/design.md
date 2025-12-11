# Design Document: Complete CI/CD Pipeline for Node.js Application

## Overview

This design document describes a complete CI/CD pipeline implementation for a Node.js application, demonstrating the full journey from development to production. The system consists of three main components:

1. **Application Server**: A simple Node.js/Express server with three routes
2. **CI/CD Pipeline**: Automated workflows using GitHub Actions for build, test, and deployment
3. **GitOps Deployment**: ArgoCD-based continuous deployment to Kubernetes clusters

The design supports two deployment approaches:
- **Simple Mode**: Docker Compose for local development and learning basic CI/CD concepts
- **Production Mode**: Kubernetes with ArgoCD for enterprise-grade GitOps deployment

This architecture teaches complete CI/CD concepts including version control, automated testing, containerization, artifact management, continuous integration, continuous deployment, environment management, and GitOps principles.

## Architecture

### High-Level Architecture

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

### Component Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Node.js Application                       │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │  /health   │  │ /api/users │  │ /api/data  │            │
│  │  endpoint  │  │  endpoint  │  │  endpoint  │            │
│  └────────────┘  └────────────┘  └────────────┘            │
│         │               │               │                    │
│         └───────────────┴───────────────┘                    │
│                         │                                     │
│                    ┌────▼────┐                               │
│                    │ Express │                               │
│                    │ Router  │                               │
│                    └────┬────┘                               │
│                         │                                     │
│                    ┌────▼────┐                               │
│                    │ Config  │                               │
│                    │ Manager │                               │
│                    └─────────┘                               │
└──────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Application Server

**Technology**: Node.js with Express framework

**Structure**:
```
src/
├── server.js           # Main entry point
├── routes/
│   ├── health.js       # Health check endpoint
│   ├── users.js        # Users API endpoint
│   └── data.js         # Data API endpoint
├── middleware/
│   ├── logger.js       # Request logging
│   └── errorHandler.js # Error handling
└── config/
    └── index.js        # Configuration management
```

**Interfaces**:

1. **Health Endpoint** (`GET /health`)
   - Returns: `{ status: "ok", timestamp: ISO8601, version: string }`
   - Status Code: 200
   - Purpose: Kubernetes liveness/readiness probes

2. **Users Endpoint** (`GET /api/users`)
   - Returns: `{ users: Array<{id, name, email}> }`
   - Status Code: 200
   - Purpose: Demonstrate data retrieval

3. **Data Endpoint** (`GET /api/data`)
   - Returns: `{ data: Array<{id, value, timestamp}> }`
   - Status Code: 200
   - Purpose: Demonstrate data processing

**Configuration**:
- Port: Environment variable `PORT` (default: 3000)
- Environment: `NODE_ENV` (development, staging, production)
- Log Level: `LOG_LEVEL` (debug, info, warn, error)

### 2. Testing Infrastructure

**Framework**: Jest

**Test Structure**:
```
tests/
├── unit/
│   ├── routes.test.js      # Route handler tests
│   └── middleware.test.js  # Middleware tests
└── integration/
    └── api.test.js         # Full API integration tests
```

**Test Coverage Requirements**:
- Minimum 80% code coverage
- All routes must have integration tests
- Error handling must be tested

### 3. Docker Containerization

**Multi-stage Dockerfile**:

```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Runtime
FROM node:18-alpine
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
WORKDIR /app
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs . .
USER nodejs
EXPOSE 3000
CMD ["node", "src/server.js"]
```

**Image Tagging Strategy**:
- `latest`: Most recent build from main branch
- `{commit-sha}`: Specific commit version
- `v{semver}`: Semantic version tags (e.g., v1.0.0)

### 4. CI/CD Pipeline Options

This design supports two CI/CD approaches:

#### Option A: GitHub Actions (Recommended for Learning)

**Advantages**:
- No infrastructure setup required
- Native GitHub integration
- Free for public repositories
- Simple YAML configuration
- Fast setup time

**Workflow Files**:

1. **`.github/workflows/ci.yml`** - Continuous Integration
   - Triggers: Push to any branch, Pull Request
   - Jobs:
     - Lint (ESLint)
     - Test (Jest with coverage)
     - Build (Docker image build test)

2. **`.github/workflows/cd-staging.yml`** - Staging Deployment
   - Triggers: Push to main branch
   - Jobs:
     - Build and push Docker image
     - Update Kubernetes manifests with new image tag
     - Commit manifest changes to trigger ArgoCD sync

3. **`.github/workflows/cd-production.yml`** - Production Deployment
   - Triggers: Manual approval after staging success
   - Jobs:
     - Update production Kubernetes manifests
     - Commit changes to trigger ArgoCD sync
     - Create GitHub release

#### Option B: Jenkins (Enterprise Standard)

**Advantages**:
- Industry-standard tool
- Highly customizable with plugins
- Self-hosted with full control
- Extensive enterprise adoption
- Rich plugin ecosystem

**Setup Requirements**:
- Jenkins server (Docker container or VM)
- Jenkins plugins: Git, Docker, Kubernetes, Pipeline
- Webhook configuration for GitHub integration

**Pipeline Files**:

1. **`Jenkinsfile.ci`** - Continuous Integration
```groovy
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }
        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }
        stage('Test') {
            steps {
                sh 'npm test -- --coverage'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t nodejs-app:${GIT_COMMIT} .'
            }
        }
    }
}
```

2. **`Jenkinsfile.cd`** - Continuous Deployment
```groovy
pipeline {
    agent any
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['staging', 'production'], description: 'Deployment environment')
        booleanParam(name: 'REQUIRE_APPROVAL', defaultValue: true, description: 'Require manual approval')
    }
    stages {
        stage('Build and Push') {
            steps {
                sh '''
                    docker build -t ghcr.io/user/nodejs-app:${GIT_COMMIT} .
                    docker push ghcr.io/user/nodejs-app:${GIT_COMMIT}
                '''
            }
        }
        stage('Approval') {
            when {
                expression { params.ENVIRONMENT == 'production' && params.REQUIRE_APPROVAL }
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
            }
        }
        stage('Update Manifests') {
            steps {
                sh '''
                    cd k8s/overlays/${ENVIRONMENT}
                    kustomize edit set image nodejs-app=ghcr.io/user/nodejs-app:${GIT_COMMIT}
                    git add .
                    git commit -m "Deploy ${GIT_COMMIT} to ${ENVIRONMENT}"
                    git push origin main
                '''
            }
        }
    }
}
```

**Jenkins Architecture**:
```
┌─────────────────────────────────────────────────────────────┐
│                      Jenkins Server                          │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   CI Job     │  │  CD Staging  │  │ CD Production│      │
│  │  (Webhook)   │  │     Job      │  │     Job      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│                    ┌───────▼────────┐                        │
│                    │  Docker Agent  │                        │
│                    └────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

**Comparison**:

| Feature | GitHub Actions | Jenkins |
|---------|---------------|---------|
| Setup Complexity | Low | Medium-High |
| Infrastructure | Managed | Self-hosted |
| Cost | Free tier | Server costs |
| Learning Curve | Easy | Moderate |
| Customization | Good | Excellent |
| Enterprise Adoption | Growing | Very High |
| Plugin Ecosystem | Marketplace | Extensive |
| Best For | Quick start, cloud-native | Enterprise, custom needs |

**Pipeline Stages**:

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Lint    │───▶│   Test   │───▶│  Build   │───▶│   Push   │
│ (ESLint) │    │  (Jest)  │    │ (Docker) │    │  (GHCR)  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
                                                       │
                                                       ▼
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Rollback │◀───│  Verify  │◀───│   Sync   │◀───│  Update  │
│(Optional)│    │ (Health) │    │ (ArgoCD) │    │(Manifest)│
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### 5. Kubernetes Deployment

**Manifest Structure**:
```
k8s/
├── base/
│   ├── deployment.yaml     # Application deployment
│   ├── service.yaml        # Service definition
│   └── configmap.yaml      # Configuration
├── overlays/
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   └── patches.yaml
│   └── production/
│       ├── kustomization.yaml
│       └── patches.yaml
└── argocd/
    ├── staging-app.yaml    # ArgoCD application for staging
    └── production-app.yaml # ArgoCD application for production
```

**Deployment Configuration**:
- Replicas: Staging (2), Production (3)
- Resource Limits: CPU (500m), Memory (512Mi)
- Resource Requests: CPU (100m), Memory (128Mi)
- Rolling Update Strategy: maxSurge 1, maxUnavailable 0
- Health Checks: Liveness and Readiness probes on /health

### 6. ArgoCD GitOps

**Application Configuration**:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nodejs-app-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/{user}/{repo}
    targetRevision: main
    path: k8s/overlays/staging
  destination:
    server: https://kubernetes.default.svc
    namespace: staging
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

**Sync Strategy**:
- Staging: Automatic sync on Git changes
- Production: Manual sync with approval
- Prune: Enabled (remove resources not in Git)
- Self-heal: Enabled (revert manual changes)

## Data Models

### Configuration Model

```javascript
{
  server: {
    port: number,
    host: string,
    environment: 'development' | 'staging' | 'production'
  },
  logging: {
    level: 'debug' | 'info' | 'warn' | 'error',
    format: 'json' | 'text'
  },
  features: {
    enableMetrics: boolean,
    enableDetailedErrors: boolean
  }
}
```

### Health Check Response Model

```javascript
{
  status: 'ok' | 'degraded' | 'error',
  timestamp: string,  // ISO 8601
  version: string,
  uptime: number,     // seconds
  environment: string
}
```

### API Response Models

**Users Response**:
```javascript
{
  users: [
    {
      id: string,
      name: string,
      email: string,
      createdAt: string
    }
  ],
  count: number
}
```

**Data Response**:
```javascript
{
  data: [
    {
      id: string,
      value: any,
      timestamp: string,
      metadata: object
    }
  ],
  count: number
}
```

### Error Response Model

```javascript
{
  error: {
    message: string,
    code: string,
    details?: object,
    timestamp: string
  }
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Universal Properties

These properties should hold across all valid inputs and executions:

**Property 1: JSON Content-Type Headers**
*For any* HTTP endpoint in the Application Server, the response SHALL include a Content-Type header with value "application/json"
**Validates: Requirements 1.5**

**Property 2: Request Logging Completeness**
*For any* HTTP request to the Application Server, the server SHALL log an entry containing timestamp, HTTP method, request path, and response status code
**Validates: Requirements 9.1**

**Property 3: Error Logging with Stack Traces**
*For any* error that occurs during request processing, the Application Server SHALL log the error with a stack trace
**Validates: Requirements 9.2**

**Property 4: Environment Variable Configuration**
*For any* configuration value in the Application Server, the value SHALL be loadable from an environment variable
**Validates: Requirements 8.1**

**Property 5: Environment-Specific Configuration**
*For any* deployment environment (development, staging, production), when the Application Server starts with that environment specified, it SHALL load configuration values specific to that environment
**Validates: Requirements 8.2, 8.3, 8.4**

### Example-Based Tests

These are specific scenarios that should be verified:

**Example 1: Health Endpoint Availability**
The `/health` endpoint SHALL return status 200 with a JSON response containing status, timestamp, version, uptime, and environment fields
**Validates: Requirements 1.1**

**Example 2: Users Endpoint Availability**
The `/api/users` endpoint SHALL return status 200 with a JSON response containing a users array
**Validates: Requirements 1.2**

**Example 3: Data Endpoint Availability**
The `/api/data` endpoint SHALL return status 200 with a JSON response containing a data array
**Validates: Requirements 1.3**

**Example 4: Startup Logging**
When the Application Server starts, it SHALL log the port number and a successful startup confirmation message
**Validates: Requirements 1.4**

**Example 5: Container Non-Root User**
The Container Image SHALL run the Application Server as a non-root user (UID 1001)
**Validates: Requirements 3.5**

**Example 6: Container Startup Time**
When the Container Image starts, the Application Server SHALL complete initialization within 10 seconds
**Validates: Requirements 3.4**

**Example 7: Multi-Stage Docker Build**
The Dockerfile SHALL use multi-stage builds with separate builder and runtime stages
**Validates: Requirements 3.2**

**Example 8: CI Pipeline Triggers**
When code is pushed to any branch, the CI workflow SHALL automatically trigger
**Validates: Requirements 4.1**

**Example 9: Test Failure Blocks Build**
When tests fail in the CI pipeline, the workflow SHALL fail and prevent image building
**Validates: Requirements 4.3**

**Example 10: Image Tagging with Commit SHA**
When a Container Image is built, it SHALL be tagged with the Git commit SHA
**Validates: Requirements 13.1**

**Example 11: Staging Auto-Deployment**
When a commit is merged to the main branch and CI passes, the CD pipeline SHALL automatically update staging manifests
**Validates: Requirements 5.1**

**Example 12: Production Manual Approval**
The production deployment workflow SHALL require manual approval before executing
**Validates: Requirements 6.1**

**Example 13: ArgoCD Auto-Sync Configuration**
The ArgoCD Application for staging SHALL have automated sync policy enabled
**Validates: Requirements 12.4**

**Example 14: Kubernetes Rolling Update Strategy**
The Kubernetes Deployment SHALL use rolling update strategy with maxSurge=1 and maxUnavailable=0
**Validates: Requirements 7.1**

**Example 15: Production JSON Logging**
When NODE_ENV is set to "production", the Application Server SHALL output logs in JSON format
**Validates: Requirements 9.4**

## Error Handling

### Application Server Error Handling

**HTTP Errors**:
- 404 Not Found: For undefined routes
- 500 Internal Server Error: For unhandled exceptions
- All errors return JSON with error object containing message, code, and timestamp

**Error Middleware**:
```javascript
function errorHandler(err, req, res, next) {
  logger.error({
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method
  });
  
  res.status(err.status || 500).json({
    error: {
      message: err.message,
      code: err.code || 'INTERNAL_ERROR',
      timestamp: new Date().toISOString()
    }
  });
}
```

**Graceful Shutdown**:
- Listen for SIGTERM and SIGINT signals
- Stop accepting new connections
- Wait for existing requests to complete (30s timeout)
- Close database connections and cleanup resources
- Exit with appropriate code

### CI/CD Pipeline Error Handling

**Build Failures**:
- Lint errors: Fail fast with detailed error output
- Test failures: Display failed test names and error messages
- Build errors: Show Docker build logs

**Deployment Failures**:
- Health check failures: Automatic rollback to previous version
- Timeout failures: Alert and halt deployment
- Manifest errors: Validate before applying

**Notification Strategy**:
- GitHub commit status updates
- GitHub Actions workflow annotations
- Optional: Slack/email notifications for production failures

### ArgoCD Error Handling

**Sync Failures**:
- Automatic retry with exponential backoff
- Maximum 5 retry attempts
- Alert after 3 consecutive failures
- Manual intervention required after max retries

**Health Check Failures**:
- Mark application as degraded
- Continue monitoring for recovery
- Alert if degraded for > 5 minutes
- Automatic rollback if configured

## Testing Strategy

### Unit Testing

**Framework**: Jest

**Coverage Requirements**:
- Minimum 80% code coverage
- 100% coverage for critical paths (error handling, configuration)

**Unit Test Scope**:
- Route handlers: Test each endpoint's logic in isolation
- Middleware: Test logging, error handling, and request processing
- Configuration: Test environment variable loading and defaults
- Utilities: Test helper functions

**Example Unit Test**:
```javascript
describe('Health Route', () => {
  it('should return 200 with health status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('status', 'ok');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body).toHaveProperty('version');
  });
});
```

### Property-Based Testing

**Framework**: fast-check (JavaScript property-based testing library)

**Configuration**:
- Minimum 100 iterations per property test
- Use seed for reproducible failures
- Shrink failing cases to minimal examples

**Property Test Implementation**:

Each property-based test MUST:
1. Be tagged with a comment referencing the design document property
2. Use the format: `// Feature: nodejs-cicd-pipeline, Property {number}: {property_text}`
3. Run at least 100 iterations
4. Test the universal property across generated inputs

**Property Test Examples**:

```javascript
// Feature: nodejs-cicd-pipeline, Property 1: JSON Content-Type Headers
describe('Property: JSON Content-Type Headers', () => {
  it('all endpoints return JSON content-type', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.constantFrom('/health', '/api/users', '/api/data'),
        async (endpoint) => {
          const response = await request(app).get(endpoint);
          expect(response.headers['content-type']).toMatch(/application\/json/);
        }
      ),
      { numRuns: 100 }
    );
  });
});

// Feature: nodejs-cicd-pipeline, Property 2: Request Logging Completeness
describe('Property: Request Logging Completeness', () => {
  it('all requests are logged with required fields', async () => {
    const logSpy = jest.spyOn(logger, 'info');
    
    await fc.assert(
      fc.asyncProperty(
        fc.constantFrom('/health', '/api/users', '/api/data'),
        fc.constantFrom('GET', 'POST', 'PUT', 'DELETE'),
        async (path, method) => {
          await request(app)[method.toLowerCase()](path);
          
          const logCalls = logSpy.mock.calls;
          const requestLog = logCalls.find(call => 
            call[0].path === path && call[0].method === method
          );
          
          expect(requestLog).toBeDefined();
          expect(requestLog[0]).toHaveProperty('timestamp');
          expect(requestLog[0]).toHaveProperty('method', method);
          expect(requestLog[0]).toHaveProperty('path', path);
          expect(requestLog[0]).toHaveProperty('statusCode');
        }
      ),
      { numRuns: 100 }
    );
  });
});

// Feature: nodejs-cicd-pipeline, Property 4: Environment Variable Configuration
describe('Property: Environment Variable Configuration', () => {
  it('all config values can be loaded from environment variables', () => {
    fc.assert(
      fc.property(
        fc.record({
          PORT: fc.integer({ min: 1000, max: 65535 }).map(String),
          NODE_ENV: fc.constantFrom('development', 'staging', 'production'),
          LOG_LEVEL: fc.constantFrom('debug', 'info', 'warn', 'error')
        }),
        (envVars) => {
          // Set environment variables
          Object.entries(envVars).forEach(([key, value]) => {
            process.env[key] = value;
          });
          
          // Load config
          const config = loadConfig();
          
          // Verify all values are loaded
          expect(config.server.port).toBe(parseInt(envVars.PORT));
          expect(config.server.environment).toBe(envVars.NODE_ENV);
          expect(config.logging.level).toBe(envVars.LOG_LEVEL);
        }
      ),
      { numRuns: 100 }
    );
  });
});
```

### Integration Testing

**Scope**:
- Full API testing with real HTTP requests
- Database integration (if applicable)
- External service mocking
- End-to-end request/response flows

**Integration Test Example**:
```javascript
describe('API Integration Tests', () => {
  let server;
  
  beforeAll(() => {
    server = app.listen(0); // Random port
  });
  
  afterAll(() => {
    server.close();
  });
  
  it('should handle complete request lifecycle', async () => {
    const response = await request(server)
      .get('/api/users')
      .expect(200)
      .expect('Content-Type', /json/);
    
    expect(response.body).toHaveProperty('users');
    expect(Array.isArray(response.body.users)).toBe(true);
  });
});
```

### CI/CD Pipeline Testing

**Workflow Validation**:
- Validate YAML syntax
- Test workflow triggers
- Verify job dependencies
- Check secret usage

**Docker Testing**:
- Build image locally
- Run container and verify startup
- Test health endpoint accessibility
- Verify non-root user

**Kubernetes Manifest Testing**:
- Validate YAML syntax with kubeval
- Dry-run apply to test cluster
- Verify resource limits and requests
- Check label selectors match

### Manual Testing Checklist

**Local Development**:
- [ ] Application starts successfully
- [ ] All endpoints respond correctly
- [ ] Logs are formatted properly
- [ ] Environment variables work

**Docker**:
- [ ] Image builds successfully
- [ ] Container starts and responds to requests
- [ ] Health checks pass
- [ ] Runs as non-root user

**CI/CD**:
- [ ] Push triggers CI workflow
- [ ] Tests run and pass
- [ ] Image is built and pushed
- [ ] Staging deploys automatically
- [ ] Production requires approval

**ArgoCD**:
- [ ] Applications are synced
- [ ] Health checks show green
- [ ] Rollback works correctly
- [ ] UI shows deployment history

## Security Considerations

### Application Security

**Container Security**:
- Run as non-root user (UID 1001)
- Use minimal base image (alpine)
- No unnecessary packages installed
- Regular base image updates

**Secrets Management**:
- Never commit secrets to Git
- Use Kubernetes Secrets for sensitive data
- Inject secrets as environment variables
- Rotate secrets regularly

**Network Security**:
- Use HTTPS in production
- Implement rate limiting
- Add CORS configuration
- Use security headers (helmet.js)

### CI/CD Security

**GitHub Actions**:
- Use pinned action versions
- Limit workflow permissions
- Use environment secrets
- Enable branch protection

**Container Registry**:
- Require authentication
- Use least-privilege access tokens
- Enable vulnerability scanning
- Implement image signing

**Kubernetes**:
- Use RBAC for access control
- Enable Pod Security Standards
- Network policies for isolation
- Regular security updates

## Deployment Strategy

### Local Development

**Setup**:
```bash
# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Start development server
npm run dev
```

**Docker Compose**:
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - PORT=3000
    volumes:
      - .:/app
      - /app/node_modules
```

### Staging Environment

**Deployment Flow**:
1. Merge PR to main branch
2. GitHub Actions builds and pushes image
3. GitHub Actions updates k8s/overlays/staging/kustomization.yaml with new image tag
4. Commits manifest change to trigger ArgoCD
5. ArgoCD detects change and syncs cluster
6. Kubernetes performs rolling update
7. Health checks verify deployment
8. Staging is live with new version

**Configuration**:
- 2 replicas
- Auto-sync enabled
- Self-heal enabled
- Prune enabled

### Production Environment

**Deployment Flow**:
1. Staging deployment succeeds
2. Manual approval requested via GitHub Actions
3. Approver reviews changes and approves
4. GitHub Actions updates k8s/overlays/production/kustomization.yaml
5. Commits manifest change
6. ArgoCD syncs production cluster
7. Rolling update with zero downtime
8. Health checks verify deployment
9. Production is live with new version

**Configuration**:
- 3 replicas
- Manual sync (approval required)
- Self-heal enabled
- Prune enabled
- Rollback on health check failure

### Rollback Strategy

**Automatic Rollback**:
- Triggered by failed health checks
- Kubernetes automatically reverts to previous ReplicaSet
- ArgoCD can revert to previous Git commit

**Manual Rollback**:
```bash
# Via kubectl
kubectl rollout undo deployment/nodejs-app -n production

# Via ArgoCD
argocd app rollback nodejs-app-production

# Via Git
git revert <commit-sha>
git push origin main
```

## Monitoring and Observability

### Application Metrics

**Exposed Metrics**:
- Request count by endpoint
- Response time percentiles (p50, p95, p99)
- Error rate by endpoint
- Active connections
- Memory usage
- CPU usage

**Metrics Endpoint**: `/metrics` (Prometheus format)

### Logging

**Log Levels**:
- DEBUG: Detailed diagnostic information
- INFO: General informational messages
- WARN: Warning messages for potential issues
- ERROR: Error messages with stack traces

**Log Format**:
```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "info",
  "message": "Request processed",
  "method": "GET",
  "path": "/api/users",
  "statusCode": 200,
  "duration": 45,
  "requestId": "abc-123"
}
```

### Health Checks

**Liveness Probe**:
- Endpoint: `/health`
- Interval: 10s
- Timeout: 5s
- Failure threshold: 3

**Readiness Probe**:
- Endpoint: `/health`
- Interval: 5s
- Timeout: 3s
- Failure threshold: 2

### Alerting

**Alert Conditions**:
- Error rate > 5% for 5 minutes
- Response time p95 > 1s for 5 minutes
- Pod restart count > 3 in 10 minutes
- Deployment sync failure
- Health check failures

## Documentation Structure

### README.md

**Sections**:
1. Project Overview
2. Prerequisites
3. Local Development Setup
4. Running Tests
5. Building Docker Image
6. Deployment Guide
7. Environment Variables
8. API Documentation
9. Troubleshooting

### CI/CD Documentation

**Files**:
- `docs/ci-cd-overview.md`: Pipeline architecture and flow
- `docs/github-actions.md`: Workflow configuration details
- `docs/argocd-setup.md`: ArgoCD installation and configuration
- `docs/deployment-guide.md`: Step-by-step deployment instructions

### API Documentation

**Format**: OpenAPI 3.0 specification

**Endpoints**:
- GET /health: Health check endpoint
- GET /api/users: Retrieve users
- GET /api/data: Retrieve data

### Runbooks

**Operational Guides**:
- Deployment rollback procedure
- Incident response workflow
- Scaling guide
- Backup and restore
- Common troubleshooting scenarios

## Technology Stack Summary

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Runtime | Node.js 18 | JavaScript runtime |
| Framework | Express | Web framework |
| Testing | Jest | Unit and integration tests |
| Property Testing | fast-check | Property-based testing |
| Linting | ESLint | Code quality |
| Containerization | Docker | Application packaging |
| Orchestration | Kubernetes | Container orchestration |
| CI/CD (Option A) | GitHub Actions | Cloud-native automation |
| CI/CD (Option B) | Jenkins | Self-hosted automation |
| GitOps | ArgoCD | Continuous deployment |
| Registry | GHCR | Container image storage |
| Version Control | Git/GitHub | Source code management |
| Local Dev | Docker Compose | Local multi-container setup |

## Learning Outcomes

By completing this project, you will learn:

1. **Version Control**: Git branching strategies, pull requests, and code review workflows
2. **Automated Testing**: Unit tests, integration tests, and property-based testing
3. **Containerization**: Docker multi-stage builds, image optimization, and security
4. **CI/CD Pipelines**: GitHub Actions workflows, automated testing, and build automation
5. **Artifact Management**: Container registry usage, image tagging, and versioning
6. **GitOps**: Declarative configuration, Git as source of truth, and automated sync
7. **Kubernetes**: Deployments, services, ConfigMaps, and rolling updates
8. **ArgoCD**: Application management, sync policies, and health monitoring
9. **Environment Management**: Configuration per environment, secrets handling
10. **Monitoring**: Logging, metrics, health checks, and alerting
11. **Deployment Strategies**: Rolling updates, zero-downtime deployments, and rollbacks
12. **Security**: Container security, secrets management, and access control

This comprehensive CI/CD pipeline demonstrates industry best practices and provides hands-on experience with modern DevOps tools and methodologies.
