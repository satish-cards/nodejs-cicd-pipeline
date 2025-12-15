#!/bin/bash

# Access Services via Minikube
# This script provides easy access to services without manual port-forwarding

echo "🚀 Minikube Service Access"
echo "=========================="
echo ""

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"
echo ""

# Get NodePort for staging
STAGING_PORT=$(kubectl get svc -n staging staging-nodejs-app -o jsonpath='{.spec.ports[0].nodePort}')
echo "📦 Staging Service:"
echo "   URL: http://$MINIKUBE_IP:$STAGING_PORT"
echo "   Health: http://$MINIKUBE_IP:$STAGING_PORT/health"
echo "   Users: http://$MINIKUBE_IP:$STAGING_PORT/api/users"
echo ""

# Get NodePort for production
PRODUCTION_PORT=$(kubectl get svc -n production production-nodejs-app -o jsonpath='{.spec.ports[0].nodePort}')
echo "🏭 Production Service:"
echo "   URL: http://$MINIKUBE_IP:$PRODUCTION_PORT"
echo "   Health: http://$MINIKUBE_IP:$PRODUCTION_PORT/health"
echo "   Users: http://$MINIKUBE_IP:$PRODUCTION_PORT/api/users"
echo ""

# Get ArgoCD NodePort (if exposed)
ARGOCD_PORT=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ -n "$ARGOCD_PORT" ]; then
    echo "🔧 ArgoCD UI:"
    echo "   URL: https://$MINIKUBE_IP:$ARGOCD_PORT"
    echo "   (Use port-forward for ArgoCD: kubectl port-forward -n argocd svc/argocd-server 8080:443)"
else
    echo "🔧 ArgoCD UI (via port-forward):"
    echo "   kubectl port-forward -n argocd svc/argocd-server 8080:443"
    echo "   Then access: https://localhost:8080"
fi
echo ""

# Test connectivity
echo "🧪 Testing Connectivity..."
echo ""

echo -n "Staging Health: "
if curl -s -f "http://$MINIKUBE_IP:$STAGING_PORT/health" > /dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

echo -n "Production Health: "
if curl -s -f "http://$MINIKUBE_IP:$PRODUCTION_PORT/health" > /dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

echo ""
echo "💡 Tip: These URLs work directly without port-forwarding!"
echo "💡 They survive pod restarts and deployments automatically."
