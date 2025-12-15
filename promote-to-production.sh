#!/bin/bash

# Promote Staging to Production
# This script helps you safely promote a tested staging deployment to production

set -e

echo "🚀 Production Deployment Helper"
echo "================================"
echo ""

# Get current staging image tag
STAGING_TAG=$(kubectl get deployment -n staging staging-nodejs-app -o jsonpath='{.spec.template.spec.containers[0].image}' | cut -d':' -f2)
STAGING_IMAGE=$(kubectl get deployment -n staging staging-nodejs-app -o jsonpath='{.spec.template.spec.containers[0].image}')

echo "📦 Current Staging Deployment:"
echo "   Image: $STAGING_IMAGE"
echo "   Tag: $STAGING_TAG"
echo ""

# Get current production image tag
PRODUCTION_TAG=$(kubectl get deployment -n production production-nodejs-app -o jsonpath='{.spec.template.spec.containers[0].image}' | cut -d':' -f2)
PRODUCTION_IMAGE=$(kubectl get deployment -n production production-nodejs-app -o jsonpath='{.spec.template.spec.containers[0].image}')

echo "🏭 Current Production Deployment:"
echo "   Image: $PRODUCTION_IMAGE"
echo "   Tag: $PRODUCTION_TAG"
echo ""

# Check if staging is healthy
STAGING_READY=$(kubectl get deployment -n staging staging-nodejs-app -o jsonpath='{.status.readyReplicas}')
STAGING_DESIRED=$(kubectl get deployment -n staging staging-nodejs-app -o jsonpath='{.spec.replicas}')

if [ "$STAGING_READY" != "$STAGING_DESIRED" ]; then
    echo "⚠️  WARNING: Staging is not fully healthy ($STAGING_READY/$STAGING_DESIRED pods ready)"
    echo "   Consider waiting for staging to stabilize before promoting to production"
    echo ""
fi

# Show available options
echo "📋 Available Image Tags:"
echo ""
echo "1. Commit SHA (Recommended): $STAGING_TAG"
echo "   - This is what's currently running in staging"
echo "   - Exact version you've tested"
echo ""
echo "2. Semantic Version: v1.0.0"
echo "   - Human-readable version"
echo "   - Points to the same image as commit SHA"
echo ""
echo "3. Latest tag: latest"
echo "   - NOT recommended for production"
echo "   - Can change unexpectedly"
echo ""

# Prompt for confirmation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Do you want to promote staging ($STAGING_TAG) to production? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Deployment cancelled"
    exit 0
fi

echo ""
echo "🔄 Updating production kustomization..."

# Update production kustomization.yaml
sed -i.bak "s|newTag: .*|newTag: $STAGING_TAG|" k8s/overlays/production/kustomization.yaml

echo "✅ Updated k8s/overlays/production/kustomization.yaml"
echo ""

# Show the diff
echo "📝 Changes to commit:"
git diff k8s/overlays/production/kustomization.yaml

echo ""
read -p "Commit and push these changes? (yes/no): " COMMIT_CONFIRM

if [ "$COMMIT_CONFIRM" != "yes" ]; then
    echo "❌ Reverting changes..."
    mv k8s/overlays/production/kustomization.yaml.bak k8s/overlays/production/kustomization.yaml
    exit 0
fi

# Commit and push
git add k8s/overlays/production/kustomization.yaml
git commit -m "Deploy to production: $STAGING_TAG"
git push origin main

echo ""
echo "✅ Changes pushed to repository"
echo ""
echo "🔧 Next Steps:"
echo "   1. ArgoCD will detect the changes (may take up to 3 minutes)"
echo "   2. Manually sync the production app in ArgoCD:"
echo "      - UI: https://localhost:8080 → nodejs-app-production → SYNC"
echo "      - CLI: argocd app sync nodejs-app-production"
echo "   3. Monitor the deployment:"
echo "      kubectl get pods -n production -w"
echo "   4. Verify health:"
echo "      curl http://\$(minikube ip):30699/health"
echo ""
echo "📊 ArgoCD Status:"
kubectl get application nodejs-app-production -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null && echo " (Sync Status)"
kubectl get application nodejs-app-production -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null && echo " (Health Status)"
echo ""

# Clean up backup
rm -f k8s/overlays/production/kustomization.yaml.bak

echo "🎉 Production deployment initiated!"
