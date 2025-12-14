# Secrets Management Guide

This guide explains how to manage sensitive configuration in the CI/CD pipeline.

## Overview

Secrets are managed using Kubernetes Secrets and are separate from ConfigMaps. Secrets should never be committed to Git in plain text.

## Creating Secrets

### Local Development

For local development, use the `.env` file (never commit this file):

```bash
cp .env.example .env
# Edit .env with your actual values
```

### Kubernetes Environments

#### Method 1: Using kubectl (Recommended for initial setup)

```bash
# Create secret for staging
kubectl create secret generic nodejs-app-secrets \
  --from-literal=API_KEY='your-staging-api-key' \
  --from-literal=JWT_SECRET='your-staging-jwt-secret' \
  --from-literal=DATABASE_URL='your-staging-db-url' \
  --namespace=staging

# Create secret for production
kubectl create secret generic nodejs-app-secrets \
  --from-literal=API_KEY='your-production-api-key' \
  --from-literal=JWT_SECRET='your-production-jwt-secret' \
  --from-literal=DATABASE_URL='your-production-db-url' \
  --namespace=production
```

#### Method 2: Using base64 encoded values

```bash
# Encode a secret value
echo -n "your-secret-value" | base64

# Create a secret YAML file (DO NOT COMMIT)
cat <<EOF > secret-temp.yaml
apiVersion: v1
kind: Secret
metadata:
  name: nodejs-app-secrets
  namespace: staging
type: Opaque
data:
  API_KEY: <base64-encoded-value>
  JWT_SECRET: <base64-encoded-value>
  DATABASE_URL: <base64-encoded-value>
EOF

# Apply the secret
kubectl apply -f secret-temp.yaml

# Delete the temporary file
rm secret-temp.yaml
```

#### Method 3: Using Sealed Secrets (Recommended for GitOps)

For production GitOps workflows, use [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets):

```bash
# Install sealed-secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml

# Install kubeseal CLI
brew install kubeseal  # macOS
# or download from releases page

# Create a sealed secret
kubectl create secret generic nodejs-app-secrets \
  --from-literal=API_KEY='your-api-key' \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > k8s/overlays/staging/sealed-secret.yaml

# Commit the sealed secret (it's encrypted)
git add k8s/overlays/staging/sealed-secret.yaml
git commit -m "Add sealed secrets for staging"
```

## GitHub Actions Secrets

For CI/CD pipelines, store secrets in GitHub:

1. Go to your repository Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `STAGING_API_KEY`
   - `STAGING_JWT_SECRET`
   - `STAGING_DATABASE_URL`
   - `PRODUCTION_API_KEY`
   - `PRODUCTION_JWT_SECRET`
   - `PRODUCTION_DATABASE_URL`

3. Update your GitHub Actions workflows to create secrets during deployment:

```yaml
- name: Create Kubernetes Secret
  run: |
    kubectl create secret generic nodejs-app-secrets \
      --from-literal=API_KEY='${{ secrets.STAGING_API_KEY }}' \
      --from-literal=JWT_SECRET='${{ secrets.STAGING_JWT_SECRET }}' \
      --from-literal=DATABASE_URL='${{ secrets.STAGING_DATABASE_URL }}' \
      --namespace=staging \
      --dry-run=client -o yaml | kubectl apply -f -
```

## Viewing Secrets

```bash
# List secrets
kubectl get secrets -n staging

# View secret details (base64 encoded)
kubectl get secret nodejs-app-secrets -n staging -o yaml

# Decode a secret value
kubectl get secret nodejs-app-secrets -n staging -o jsonpath='{.data.API_KEY}' | base64 --decode
```

## Rotating Secrets

```bash
# Update a secret
kubectl create secret generic nodejs-app-secrets \
  --from-literal=API_KEY='new-api-key' \
  --from-literal=JWT_SECRET='new-jwt-secret' \
  --from-literal=DATABASE_URL='new-db-url' \
  --namespace=staging \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new secrets
kubectl rollout restart deployment/staging-nodejs-app -n staging
```

## Security Best Practices

1. **Never commit secrets to Git** - Use `.gitignore` for `.env` files
2. **Use different secrets per environment** - Staging and production should have different values
3. **Rotate secrets regularly** - Change secrets periodically
4. **Use RBAC** - Limit who can view/edit secrets in Kubernetes
5. **Enable encryption at rest** - Configure Kubernetes to encrypt secrets in etcd
6. **Use external secret managers** - Consider AWS Secrets Manager, HashiCorp Vault, or Azure Key Vault for production
7. **Audit secret access** - Enable audit logging for secret access

## Environment-Specific Configuration

### Development
- Uses `.env` file
- Secrets are optional
- Detailed error messages enabled

### Staging
- Uses Kubernetes ConfigMaps for non-sensitive config
- Uses Kubernetes Secrets for sensitive data
- Moderate logging level
- Similar to production but with more verbose logging

### Production
- Uses Kubernetes ConfigMaps for non-sensitive config
- Uses Kubernetes Secrets for sensitive data
- JSON formatted logs
- Minimal error details exposed
- Higher security standards

## Troubleshooting

### Secret not found error
```bash
# Check if secret exists
kubectl get secret nodejs-app-secrets -n staging

# If missing, create it using one of the methods above
```

### Pod can't read secret
```bash
# Check pod events
kubectl describe pod <pod-name> -n staging

# Verify secret is mounted correctly
kubectl get deployment staging-nodejs-app -n staging -o yaml | grep -A 10 secretKeyRef
```

### Wrong secret value
```bash
# Verify the secret value
kubectl get secret nodejs-app-secrets -n staging -o jsonpath='{.data.API_KEY}' | base64 --decode

# Update if incorrect
kubectl create secret generic nodejs-app-secrets \
  --from-literal=API_KEY='correct-value' \
  --namespace=staging \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart deployment
kubectl rollout restart deployment/staging-nodejs-app -n staging
```
