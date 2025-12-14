#!/bin/bash

echo "=== Production Service Exposure Options ==="
echo ""

# Option 1: Port Forward (Current - Easy)
echo "1. PORT FORWARD (Recommended for testing)"
echo "   Command: kubectl port-forward -n production svc/production-nodejs-app 8080:80"
echo "   Access:  http://localhost:8080"
echo ""

# Option 2: NodePort
echo "2. NODEPORT (Access via Node IP)"
echo "   This will expose production on a high port (30000-32767) on all nodes"
echo ""
read -p "   Do you want to change to NodePort? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl patch service production-nodejs-app -n production -p '{"spec":{"type":"NodePort"}}'
    echo "   ✅ Service changed to NodePort"
    echo ""
    NODE_PORT=$(kubectl get service production-nodejs-app -n production -o jsonpath='{.spec.ports[0].nodePort}')
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    echo "   Access at: http://${NODE_IP}:${NODE_PORT}"
    echo "   Or if using Docker Desktop/Minikube: http://localhost:${NODE_PORT}"
fi
echo ""

# Option 3: LoadBalancer
echo "3. LOADBALANCER (Cloud environments)"
echo "   This creates an external load balancer (works on cloud providers)"
echo ""
read -p "   Do you want to change to LoadBalancer? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl patch service production-nodejs-app -n production -p '{"spec":{"type":"LoadBalancer"}}'
    echo "   ✅ Service changed to LoadBalancer"
    echo "   Waiting for external IP..."
    kubectl get service production-nodejs-app -n production -w
fi
echo ""

# Option 4: Ingress
echo "4. INGRESS (Production-ready with domain)"
echo "   This uses Ingress controller for HTTP routing"
echo ""
read -p "   Do you want to create an Ingress? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: production-nodejs-app
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: production.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: production-nodejs-app
            port:
              number: 80
EOF
    echo "   ✅ Ingress created"
    echo ""
    echo "   Add to /etc/hosts:"
    INGRESS_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$INGRESS_IP" ]; then
        INGRESS_IP="127.0.0.1"
    fi
    echo "   ${INGRESS_IP} production.local"
    echo ""
    echo "   Then access at: http://production.local"
fi
echo ""

echo "=== Current Service Status ==="
kubectl get service production-nodejs-app -n production
