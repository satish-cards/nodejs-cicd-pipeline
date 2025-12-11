#!/bin/bash

# Kubernetes and ArgoCD Status Checker
# This script checks the status of your K8s cluster and ArgoCD setup

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "=========================================="
echo "Kubernetes & ArgoCD Status Check"
echo "=========================================="
echo ""

# Check Minikube
echo -e "${BLUE}Minikube:${NC}"
if minikube status &> /dev/null; then
    check_pass "Minikube is running"
    echo "  $(minikube status | grep host | awk '{print $1": "$2}')"
else
    check_fail "Minikube is not running"
    echo "  Run: ./setup-k8s-argocd.sh"
fi
echo ""

# Check kubectl
echo -e "${BLUE}Kubernetes Cluster:${NC}"
if kubectl cluster-info &> /dev/null; then
    check_pass "Cluster is accessible"
    NODES=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
    echo "  Nodes: $NODES"
else
    check_fail "Cannot connect to cluster"
fi
echo ""

# Check namespaces
echo -e "${BLUE}Namespaces:${NC}"
for ns in argocd staging production; do
    if kubectl get namespace $ns &> /dev/null; then
        check_pass "$ns namespace exists"
    else
        check_fail "$ns namespace missing"
    fi
done
echo ""

# Check ArgoCD
echo -e "${BLUE}ArgoCD:${NC}"
if kubectl get namespace argocd &> /dev/null; then
    ARGOCD_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l | tr -d ' ')
    ARGOCD_READY=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep Running | wc -l | tr -d ' ')
    
    if [ "$ARGOCD_PODS" -gt 0 ]; then
        if [ "$ARGOCD_PODS" -eq "$ARGOCD_READY" ]; then
            check_pass "ArgoCD is running ($ARGOCD_READY/$ARGOCD_PODS pods ready)"
        else
            check_warn "ArgoCD is starting ($ARGOCD_READY/$ARGOCD_PODS pods ready)"
        fi
    else
        check_fail "ArgoCD is not installed"
    fi
    
    # Check ArgoCD password
    if kubectl get secret argocd-initial-admin-secret -n argocd &> /dev/null; then
        PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
        if [ -n "$PASSWORD" ]; then
            echo "  Admin password: $PASSWORD"
        fi
    fi
else
    check_fail "ArgoCD namespace not found"
fi
echo ""

# Check GHCR secrets
echo -e "${BLUE}GHCR Image Pull Secrets:${NC}"
for ns in staging production; do
    if kubectl get secret ghcr-secret -n $ns &> /dev/null; then
        check_pass "Secret exists in $ns"
    else
        check_fail "Secret missing in $ns"
        echo "  Run: ./setup-ghcr-secrets.sh"
    fi
done
echo ""

# Check ArgoCD applications
echo -e "${BLUE}ArgoCD Applications:${NC}"
if kubectl get applications -n argocd &> /dev/null 2>&1; then
    APPS=$(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l | tr -d ' ')
    if [ "$APPS" -gt 0 ]; then
        check_pass "$APPS application(s) deployed"
        kubectl get applications -n argocd --no-headers 2>/dev/null | while read line; do
            APP_NAME=$(echo $line | awk '{print $1}')
            SYNC_STATUS=$(echo $line | awk '{print $2}')
            HEALTH_STATUS=$(echo $line | awk '{print $3}')
            echo "  - $APP_NAME: Sync=$SYNC_STATUS, Health=$HEALTH_STATUS"
        done
    else
        check_warn "No applications deployed"
        echo "  Run: kubectl apply -f k8s/argocd/staging-app.yaml"
    fi
else
    check_warn "No applications found"
fi
echo ""

# Check application pods
echo -e "${BLUE}Application Pods:${NC}"
for ns in staging production; do
    PODS=$(kubectl get pods -n $ns --no-headers 2>/dev/null | wc -l | tr -d ' ')
    if [ "$PODS" -gt 0 ]; then
        RUNNING=$(kubectl get pods -n $ns --no-headers 2>/dev/null | grep Running | wc -l | tr -d ' ')
        if [ "$PODS" -eq "$RUNNING" ]; then
            check_pass "$ns: $RUNNING/$PODS pods running"
        else
            check_warn "$ns: $RUNNING/$PODS pods running"
        fi
        kubectl get pods -n $ns --no-headers 2>/dev/null | while read line; do
            POD_NAME=$(echo $line | awk '{print $1}')
            POD_STATUS=$(echo $line | awk '{print $3}')
            echo "  - $POD_NAME: $POD_STATUS"
        done
    else
        check_warn "$ns: No pods found"
    fi
done
echo ""

# Check services
echo -e "${BLUE}Services:${NC}"
for ns in staging production; do
    SERVICES=$(kubectl get svc -n $ns --no-headers 2>/dev/null | wc -l | tr -d ' ')
    if [ "$SERVICES" -gt 0 ]; then
        check_pass "$ns: $SERVICES service(s)"
        kubectl get svc -n $ns --no-headers 2>/dev/null | while read line; do
            SVC_NAME=$(echo $line | awk '{print $1}')
            SVC_TYPE=$(echo $line | awk '{print $2}')
            echo "  - $SVC_NAME ($SVC_TYPE)"
        done
    else
        check_warn "$ns: No services found"
    fi
done
echo ""

# Summary
echo "=========================================="
echo -e "${BLUE}Quick Access Commands:${NC}"
echo "=========================================="
echo ""
echo "ArgoCD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Then open: https://localhost:8080"
echo ""
echo "Application (Staging):"
echo "  kubectl port-forward svc/staging-nodejs-app -n staging 3000:3000"
echo "  Then open: http://localhost:3000/health"
echo ""
echo "Or use Minikube service:"
echo "  minikube service staging-nodejs-app -n staging"
echo ""
echo "View logs:"
echo "  kubectl logs -f deployment/staging-nodejs-app -n staging"
echo ""
