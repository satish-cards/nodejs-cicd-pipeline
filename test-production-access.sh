#!/bin/bash

echo "=== Testing Production Access ==="
echo ""

# Method 1: Port Forward
echo "1. Testing Port Forward..."
kubectl port-forward -n production svc/production-nodejs-app 8080:80 > /dev/null 2>&1 &
PF_PID=$!
sleep 3

if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "   ✅ Port Forward works!"
    echo "   Access at: http://localhost:8080/health"
    curl -s http://localhost:8080/health | jq -r '.environment'
else
    echo "   ❌ Port Forward failed"
fi

kill $PF_PID 2>/dev/null
wait $PF_PID 2>/dev/null
echo ""

# Method 2: Ingress via NodePort
echo "2. Testing Ingress (via NodePort 32372)..."
if curl -s -H "Host: production.local" http://localhost:32372/health > /dev/null 2>&1; then
    echo "   ✅ Ingress works!"
    echo "   Access at: http://localhost:32372/health (with Host header)"
    echo "   Or add to /etc/hosts: 127.0.0.1 production.local"
    echo "   Then access at: http://production.local/health"
else
    echo "   ⚠️  Ingress not responding yet (may need a moment to configure)"
    echo "   Try: curl -H 'Host: production.local' http://localhost:32372/health"
fi
echo ""

# Method 3: Direct service access (from within cluster)
echo "3. Testing Direct Service Access (from pod)..."
if kubectl exec -n production deployment/production-nodejs-app -- wget -qO- http://production-nodejs-app.production.svc.cluster.local/health > /dev/null 2>&1; then
    echo "   ✅ Service accessible from within cluster"
else
    echo "   ⚠️  Service not accessible from within cluster"
fi
echo ""

echo "=== Summary ==="
echo "Production is running on 3 replicas"
echo ""
echo "Access Methods:"
echo "  1. Port Forward:  kubectl port-forward -n production svc/production-nodejs-app 8080:80"
echo "                    Then: http://localhost:8080/health"
echo ""
echo "  2. Ingress:       Add to /etc/hosts: 127.0.0.1 production.local"
echo "                    Then: http://production.local/health"
echo ""
echo "  3. NodePort:      http://localhost:32372/health (with Host: production.local header)"
echo ""
