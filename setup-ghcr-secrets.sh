#!/bin/bash

# GitHub Container Registry Secrets Setup Script
# This script creates Kubernetes secrets for pulling images from GHCR

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo "=========================================="
echo "GitHub Container Registry Secrets Setup"
echo "=========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Is minikube running?"
    exit 1
fi

# Prompt for GitHub credentials
echo -e "${BLUE}Enter your GitHub credentials:${NC}"
echo ""
read -p "GitHub Username: " GITHUB_USERNAME
read -sp "GitHub Personal Access Token (PAT): " GITHUB_TOKEN
echo ""
read -p "GitHub Email: " GITHUB_EMAIL
echo ""

if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_EMAIL" ]; then
    print_error "All fields are required"
    exit 1
fi

print_step "Creating image pull secrets..."

# Create secret for staging namespace
if kubectl get secret ghcr-secret -n staging &> /dev/null; then
    print_warning "Secret already exists in staging namespace, deleting..."
    kubectl delete secret ghcr-secret -n staging
fi

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username="$GITHUB_USERNAME" \
  --docker-password="$GITHUB_TOKEN" \
  --docker-email="$GITHUB_EMAIL" \
  -n staging

print_success "Secret created in staging namespace"

# Create secret for production namespace
if kubectl get secret ghcr-secret -n production &> /dev/null; then
    print_warning "Secret already exists in production namespace, deleting..."
    kubectl delete secret ghcr-secret -n production
fi

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username="$GITHUB_USERNAME" \
  --docker-password="$GITHUB_TOKEN" \
  --docker-email="$GITHUB_EMAIL" \
  -n production

print_success "Secret created in production namespace"

echo ""
echo "=========================================="
echo -e "${GREEN}Secrets Created Successfully!${NC}"
echo "=========================================="
echo ""
echo "Verify secrets:"
echo "  kubectl get secret ghcr-secret -n staging"
echo "  kubectl get secret ghcr-secret -n production"
echo ""
echo -e "${YELLOW}Note:${NC} Your GitHub PAT needs 'read:packages' permission"
echo "Create one at: https://github.com/settings/tokens"
echo ""
