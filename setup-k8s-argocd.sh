#!/bin/bash

# Kubernetes and ArgoCD Setup Script
# This script automates the setup of a local Kubernetes cluster with ArgoCD

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check prerequisites
print_step "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker Desktop first."
    exit 1
fi
print_success "Docker is installed"

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Install with: brew install kubectl"
    exit 1
fi
print_success "kubectl is installed"

if ! command -v minikube &> /dev/null; then
    print_error "minikube is not installed. Install with: brew install minikube"
    exit 1
fi
print_success "minikube is installed"

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi
print_success "Docker is running"

# Step 1: Start Minikube
print_step "Starting Minikube cluster..."
if minikube status &> /dev/null; then
    print_warning "Minikube is already running"
else
    minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=20g
    print_success "Minikube cluster started"
fi

# Verify cluster
kubectl cluster-info &> /dev/null
print_success "Kubernetes cluster is accessible"

# Step 2: Enable addons
print_step "Enabling Minikube addons..."
minikube addons enable metrics-server
minikube addons enable ingress
print_success "Addons enabled"

# Step 3: Install ArgoCD
print_step "Installing ArgoCD..."

# Create namespace if it doesn't exist
if kubectl get namespace argocd &> /dev/null; then
    print_warning "ArgoCD namespace already exists"
else
    kubectl create namespace argocd
    print_success "ArgoCD namespace created"
fi

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

print_step "Waiting for ArgoCD pods to be ready (this may take 2-3 minutes)..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
print_success "ArgoCD is ready"

# Step 4: Get ArgoCD password
print_step "Retrieving ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
print_success "ArgoCD admin password retrieved"

# Step 5: Create namespaces
print_step "Creating application namespaces..."
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
print_success "Namespaces created"

# Step 6: Patch ArgoCD server for NodePort access
print_step "Configuring ArgoCD server access..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
print_success "ArgoCD server configured"

# Get ArgoCD URL
ARGOCD_URL=$(minikube service argocd-server -n argocd --url | head -1)

# Print summary
echo ""
echo "=========================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Cluster Information:${NC}"
echo "  Minikube Status: $(minikube status | grep host | awk '{print $2}')"
echo "  Kubernetes Version: $(kubectl version --short 2>/dev/null | grep Server | awk '{print $3}')"
echo ""
echo -e "${BLUE}ArgoCD Access:${NC}"
echo "  URL: ${ARGOCD_URL}"
echo "  Username: admin"
echo "  Password: ${ARGOCD_PASSWORD}"
echo ""
echo -e "${BLUE}Alternative Access (Port Forward):${NC}"
echo "  Run: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Then access: https://localhost:8080"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Configure GHCR image pull secrets (see docs/kubernetes-argocd-setup.md)"
echo "  2. Update repository URLs in k8s/argocd/*.yaml files"
echo "  3. Deploy ArgoCD applications: kubectl apply -f k8s/argocd/"
echo "  4. Push code to main branch to trigger deployment"
echo ""
echo -e "${YELLOW}Important:${NC} Save the ArgoCD password above!"
echo ""

# Offer to open ArgoCD UI
read -p "Would you like to open ArgoCD UI in your browser? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Opening ArgoCD UI..."
    open "${ARGOCD_URL}"
fi

# Offer to start port forwarding
read -p "Would you like to start port forwarding for ArgoCD? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Starting port forwarding on https://localhost:8080..."
    print_warning "Press Ctrl+C to stop port forwarding"
    kubectl port-forward svc/argocd-server -n argocd 8080:443
fi
