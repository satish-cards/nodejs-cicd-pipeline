# How to Access Production Application

## Quick Answer

You have **3 easy ways** to access the production application:

---

## ✅ Option 1: Port Forward (Easiest)

**Best for**: Quick testing, development

```bash
kubectl port-forward -n production svc/production-nodejs-app 8080:80
```

Then access at:
- **Health**: http://localhost:8080/health
- **Users API**: http://localhost:8080/api/users
- **Data API**: http://localhost:8080/api/data

**Pros**: Simple, no configuration needed  
**Cons**: Only works while command is running

---

## ✅ Option 2: Ingress (Recommended) ⭐

**Best for**: Production-like access with domain name

### Step 1: Add to /etc/hosts

```bash
echo "127.0.0.1 production.local" | sudo tee -a /etc/hosts
```

### Step 2: Access via domain

The Ingress is already configured! Access at:
- **Health**: http://production.local/health
- **Users API**: http://production.local/api/users
- **Data API**: http://production.local/api/data

**Note**: The Ingress controller is running on port **32372** (NodePort), but if you're using Docker Desktop or Minikube, it should work on port 80 automatically.

If port 80 doesn't work, try:
- http://production.local:32372/health

**Pros**: Production-like setup, domain name  
**Cons**: Requires /etc/hosts modification

---

## ✅ Option 3: Direct NodePort

**Best for**: Accessing via IP address

### Find the NodePort

```bash
kubectl get service -n ingress-nginx ingress-nginx-controller
```

Current NodePort: **32372**

### Access via localhost

- **Health**: http://localhost:32372/health
- **Users API**: http://localhost:32372/api/users
- **Data API**: http://localhost:32372/api/data

**Pros**: No configuration needed  
**Cons**: Uses high port number

---

## Current Setup

### Service Configuration
```
Type:        ClusterIP
Port:        80 (forwards to container port 3000)
Namespace:   production
```

### Ingress Configuration
```
Host:        production.local
Port:        80 (via Ingress controller on NodePort 32372)
Class:       nginx
```

### Ingress Controller
```
Type:        NodePort
HTTP Port:   32372
HTTPS Port:  31599
```

---

## Quick Test Commands

### Test with Port Forward
```bash
# Terminal 1: Start port forward
kubectl port-forward -n production svc/production-nodejs-app 8080:80

# Terminal 2: Test
curl http://localhost:8080/health
```

### Test with Ingress (after adding to /etc/hosts)
```bash
curl http://production.local/health
# or
curl http://localhost:32372/health
```

### Test with NodePort directly
```bash
curl http://localhost:32372/health
```

---

## Comparison: Staging vs Production Access

| Environment | Method | URL |
|-------------|--------|-----|
| **Staging** | Port Forward | http://localhost:8080 |
| **Staging** | Ingress | http://staging.local |
| **Production** | Port Forward | http://localhost:8080 |
| **Production** | Ingress | http://production.local |
| **Production** | NodePort | http://localhost:32372 |

---

## Making It Permanent

### Option A: Keep Ingress (Recommended)

The Ingress is already created. Just add to /etc/hosts:

```bash
echo "127.0.0.1 production.local" | sudo tee -a /etc/hosts
```

### Option B: Change to NodePort

If you want the service itself to be NodePort:

```bash
kubectl patch service production-nodejs-app -n production -p '{"spec":{"type":"NodePort"}}'
```

Then check the assigned port:
```bash
kubectl get service production-nodejs-app -n production
```

### Option C: Change to LoadBalancer

For cloud environments (AWS, GCP, Azure):

```bash
kubectl patch service production-nodejs-app -n production -p '{"spec":{"type":"LoadBalancer"}}'
```

---

## Troubleshooting

### Can't access via production.local

1. Check /etc/hosts:
   ```bash
   cat /etc/hosts | grep production.local
   ```

2. Should see:
   ```
   127.0.0.1 production.local
   ```

3. Try with port:
   ```bash
   curl http://production.local:32372/health
   ```

### Port forward not working

1. Check if port is already in use:
   ```bash
   lsof -i :8080
   ```

2. Try a different port:
   ```bash
   kubectl port-forward -n production svc/production-nodejs-app 9090:80
   ```

### Ingress not working

1. Check Ingress status:
   ```bash
   kubectl get ingress -n production
   kubectl describe ingress production-nodejs-app -n production
   ```

2. Check Ingress controller:
   ```bash
   kubectl get pods -n ingress-nginx
   ```

3. Check Ingress controller logs:
   ```bash
   kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
   ```

---

## Recommended Setup

For the best experience, I recommend:

1. **Add to /etc/hosts**:
   ```bash
   echo "127.0.0.1 production.local" | sudo tee -a /etc/hosts
   echo "127.0.0.1 staging.local" | sudo tee -a /etc/hosts
   ```

2. **Access production**:
   - http://production.local/health
   - http://production.local/api/users
   - http://production.local/api/data

3. **Access staging** (if you create staging ingress):
   - http://staging.local/health
   - http://staging.local/api/users
   - http://staging.local/api/data

---

## Summary

**Easiest**: Port forward to localhost:8080  
**Best**: Ingress with production.local domain  
**Alternative**: Direct NodePort on localhost:32372

All three methods work - choose based on your preference!
