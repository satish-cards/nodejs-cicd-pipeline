# Environment-Specific Configuration Guide

This guide explains how environment-specific configuration is managed across different deployment environments.

## Overview

The application uses a layered configuration approach:
1. **Default values** - Hardcoded in `src/config/index.js`
2. **Environment variables** - Loaded from `.env` file (local) or Kubernetes ConfigMaps/Secrets (deployed)
3. **Environment-specific overrides** - Different values per environment (dev, staging, production)

## Configuration Sources

### Local Development
- `.env` file (copy from `.env.example`)
- Environment variables set in your shell
- Default values from `src/config/index.js`

### Kubernetes Deployments
- **ConfigMaps** - Non-sensitive configuration (`k8s/base/configmap.yaml`)
- **Secrets** - Sensitive data like API keys (`k8s/base/secret.yaml`)
- **Environment overlays** - Environment-specific values in `k8s/overlays/{env}/`

## Configuration Variables

### Server Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `PORT` | number | 3000 | HTTP server port |
| `HOST` | string | 0.0.0.0 | Server bind address |
| `NODE_ENV` | string | development | Environment name (development, staging, production) |

### Logging Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `LOG_LEVEL` | string | info | Log level (debug, info, warn, error) |
| Log Format | string | auto | Automatically set: 'json' in production, 'text' otherwise |

### Application Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `APP_VERSION` | string | 1.0.0 | Application version |
| `ENABLE_METRICS` | boolean | false | Enable Prometheus metrics endpoint |
| `ENABLE_DETAILED_ERRORS` | boolean | true | Include stack traces in error responses |

### Secrets (Optional)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `API_KEY` | string | "" | External API key |
| `JWT_SECRET` | string | "" | JWT signing secret |
| `DATABASE_URL` | string | "" | Database connection string |

## Environment-Specific Settings

### Development Environment

**Purpose**: Local development and testing

**Configuration**:
```bash
NODE_ENV=development
LOG_LEVEL=debug
ENABLE_METRICS=false
ENABLE_DETAILED_ERRORS=true
```

**Characteristics**:
- Verbose logging with debug information
- Text-formatted logs for readability
- Detailed error messages with stack traces
- Hot reload enabled
- No metrics collection

**Setup**:
```bash
cp .env.example .env
npm run dev
```

### Staging Environment

**Purpose**: Pre-production testing and validation

**Configuration** (from `k8s/overlays/staging/kustomization.yaml`):
```yaml
NODE_ENV=staging
LOG_LEVEL=info
ENABLE_METRICS=true
ENABLE_DETAILED_ERRORS=true
```

**Characteristics**:
- JSON-formatted logs (same as production)
- Moderate logging level
- Detailed errors for debugging
- Metrics collection enabled
- 2 replicas for availability
- Auto-sync with ArgoCD

**Deployment**:
- Automatically deployed on merge to main branch
- Uses staging-specific ConfigMap and Secrets
- Namespace: `staging`

### Production Environment

**Purpose**: Live production workload

**Configuration** (from `k8s/overlays/production/kustomization.yaml`):
```yaml
NODE_ENV=production
LOG_LEVEL=warn
ENABLE_METRICS=true
ENABLE_DETAILED_ERRORS=false
```

**Characteristics**:
- JSON-formatted logs for parsing
- Minimal logging (warnings and errors only)
- No detailed error information exposed
- Metrics collection enabled
- 3 replicas for high availability
- Manual approval required for deployment

**Deployment**:
- Requires manual approval
- Uses production-specific ConfigMap and Secrets
- Namespace: `production`
- Rollback on health check failure

## Configuration Loading Process

### 1. Application Startup

```javascript
// src/config/index.js
require('dotenv').config();  // Load .env file (local only)

const config = {
  server: {
    port: parseInt(process.env.PORT, 10) || 3000,
    environment: process.env.NODE_ENV || 'development'
  },
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    format: process.env.NODE_ENV === 'production' ? 'json' : 'text'
  },
  // ... more config
};
```

### 2. Kubernetes Injection

Environment variables are injected into pods from ConfigMaps and Secrets:

```yaml
env:
  - name: NODE_ENV
    valueFrom:
      configMapKeyRef:
        name: nodejs-app-config
        key: NODE_ENV
  - name: API_KEY
    valueFrom:
      secretKeyRef:
        name: nodejs-app-secrets
        key: API_KEY
```

### 3. Runtime Access

```javascript
const config = require('./config');

// Access configuration
console.log(config.server.port);
console.log(config.logging.level);
console.log(config.features.enableMetrics);
```

## Updating Configuration

### Local Development

Edit `.env` file and restart the server:
```bash
# Edit .env
vim .env

# Restart server
npm run dev
```

### Staging/Production

#### Non-Sensitive Configuration (ConfigMap)

1. Edit the overlay kustomization file:
```bash
vim k8s/overlays/staging/kustomization.yaml
```

2. Update the configMapGenerator literals:
```yaml
configMapGenerator:
  - name: nodejs-app-config
    behavior: merge
    literals:
      - LOG_LEVEL=debug  # Changed value
```

3. Commit and push:
```bash
git add k8s/overlays/staging/kustomization.yaml
git commit -m "Update staging log level to debug"
git push origin main
```

4. ArgoCD will automatically sync the changes

5. Restart pods to pick up new ConfigMap:
```bash
kubectl rollout restart deployment/staging-nodejs-app -n staging
```

#### Sensitive Configuration (Secrets)

See [k8s/SECRETS-MANAGEMENT.md](../k8s/SECRETS-MANAGEMENT.md) for detailed instructions.

Quick example:
```bash
kubectl create secret generic nodejs-app-secrets \
  --from-literal=API_KEY='new-value' \
  --namespace=staging \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment/staging-nodejs-app -n staging
```

## Validation

### Verify Configuration Loading

Check the application logs on startup:
```bash
# Local
npm start

# Kubernetes
kubectl logs -f deployment/staging-nodejs-app -n staging
```

Look for startup log:
```json
{
  "timestamp": "2024-01-15T10:00:00.000Z",
  "level": "info",
  "message": "Server started successfully on port 3000",
  "port": 3000,
  "environment": "staging"
}
```

### Test Configuration via API

```bash
# Health endpoint shows environment
curl http://localhost:3000/health

# Response includes environment info
{
  "status": "ok",
  "timestamp": "2024-01-15T10:00:00.000Z",
  "version": "1.0.0",
  "uptime": 123,
  "environment": "staging"
}
```

### Verify Environment Variables in Pod

```bash
kubectl exec -it deployment/staging-nodejs-app -n staging -- env | grep NODE_ENV
kubectl exec -it deployment/staging-nodejs-app -n staging -- env | grep LOG_LEVEL
```

## Troubleshooting

### Configuration not loading

**Problem**: Application uses default values instead of environment variables

**Solutions**:
1. Check if ConfigMap exists:
   ```bash
   kubectl get configmap nodejs-app-config -n staging
   ```

2. Verify ConfigMap contents:
   ```bash
   kubectl describe configmap nodejs-app-config -n staging
   ```

3. Check pod environment variables:
   ```bash
   kubectl exec deployment/staging-nodejs-app -n staging -- env
   ```

4. Restart deployment:
   ```bash
   kubectl rollout restart deployment/staging-nodejs-app -n staging
   ```

### Wrong log format

**Problem**: Logs are in text format in production

**Solution**: Verify NODE_ENV is set to "production":
```bash
kubectl get configmap nodejs-app-config -n production -o yaml | grep NODE_ENV
```

### Secrets not accessible

**Problem**: Application can't read secret values

**Solutions**:
1. Check if secret exists:
   ```bash
   kubectl get secret nodejs-app-secrets -n staging
   ```

2. Verify secret is referenced in deployment:
   ```bash
   kubectl get deployment staging-nodejs-app -n staging -o yaml | grep -A 5 secretKeyRef
   ```

3. Check pod events for errors:
   ```bash
   kubectl describe pod <pod-name> -n staging
   ```

See [k8s/SECRETS-MANAGEMENT.md](../k8s/SECRETS-MANAGEMENT.md) for more troubleshooting.

## Best Practices

1. **Never commit secrets** - Use `.gitignore` for `.env` files
2. **Use different secrets per environment** - Staging and production should never share secrets
3. **Document all variables** - Keep this guide and `.env.example` up to date
4. **Validate on startup** - Log configuration on application start
5. **Use sensible defaults** - Application should work with minimal configuration
6. **Fail fast** - Validate required configuration early in startup
7. **Restart after changes** - Always restart pods after ConfigMap/Secret updates
8. **Test in staging first** - Validate configuration changes in staging before production

## Adding New Configuration

To add a new configuration variable:

1. **Update `.env.example`**:
   ```bash
   # New Configuration
   NEW_VARIABLE=default-value
   ```

2. **Update `src/config/index.js`**:
   ```javascript
   const config = {
     // ... existing config
     newFeature: {
       variable: process.env.NEW_VARIABLE || 'default-value'
     }
   };
   ```

3. **Update ConfigMap** (if non-sensitive):
   ```yaml
   # k8s/base/configmap.yaml
   data:
     NEW_VARIABLE: "default-value"
   ```

4. **Update Deployment**:
   ```yaml
   # k8s/base/deployment.yaml
   env:
     - name: NEW_VARIABLE
       valueFrom:
         configMapKeyRef:
           name: nodejs-app-config
           key: NEW_VARIABLE
   ```

5. **Update environment overlays** if needed:
   ```yaml
   # k8s/overlays/production/kustomization.yaml
   configMapGenerator:
     - name: nodejs-app-config
       behavior: merge
       literals:
         - NEW_VARIABLE=production-value
   ```

6. **Document** in this guide and update tests

7. **Test** in all environments
