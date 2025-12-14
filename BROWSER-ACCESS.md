# Browser Access to Staging and Production

## ✅ Direct Browser Access

Both environments are now exposed as **NodePort** services and can be accessed directly from your browser!

### 🟦 Staging Environment
**Port**: 30690

- **Health Check**: http://localhost:30690/health
- **Users API**: http://localhost:30690/api/users
- **Data API**: http://localhost:30690/api/data

### 🟩 Production Environment
**Port**: 30699

- **Health Check**: http://localhost:30699/health
- **Users API**: http://localhost:30699/api/users
- **Data API**: http://localhost:30699/api/data

---

## Quick Test

Open these URLs in your browser:

1. **Staging Health**: [http://localhost:30690/health](http://localhost:30690/health)
2. **Production Health**: [http://localhost:30699/health](http://localhost:30699/health)

You should see JSON responses with environment information!

---

## Service Configuration

### Staging Service
```yaml
Type: NodePort
Port: 80 → 3000 (container)
NodePort: 30690
Namespace: staging
```

### Production Service
```yaml
Type: NodePort
Port: 80 → 3000 (container)
NodePort: 30699
Namespace: production
```

---

## Verification Commands

### Check Services
```bash
# Staging
kubectl get service staging-nodejs-app -n staging

# Production
kubectl get service production-nodejs-app -n production
```

### Test with curl
```bash
# Staging
curl http://localhost:30690/health

# Production
curl http://localhost:30699/health
```

---

## Configuration Differences

When you access these URLs, you'll see different configurations:

### Staging Response
```json
{
  "status": "Working Fine",
  "timestamp": "2025-12-11T...",
  "version": "1.0.0",
  "uptime": 123,
  "environment": "staging"
}
```

### Production Response
```json
{
  "status": "Working Fine",
  "timestamp": "2025-12-11T...",
  "version": "1.0.0",
  "uptime": 456,
  "environment": "production"
}
```

**Key Difference**: Production logs are in JSON format, staging uses text format.

---

## All Available Endpoints

### Staging (port 30690)
| Endpoint | URL | Description |
|----------|-----|-------------|
| Health | http://localhost:30690/health | Health check |
| Users | http://localhost:30690/api/users | Sample user data |
| Data | http://localhost:30690/api/data | Sample data |

### Production (port 30699)
| Endpoint | URL | Description |
|----------|-----|-------------|
| Health | http://localhost:30699/health | Health check |
| Users | http://localhost:30699/api/users | Sample user data |
| Data | http://localhost:30699/api/data | Sample data |

---

## Troubleshooting

### Can't access localhost:30690 or localhost:30699

**On Docker Desktop for Mac/Windows:**
NodePort services should work directly on localhost.

**If it doesn't work:**

1. Check if services are running:
   ```bash
   kubectl get services -n staging
   kubectl get services -n production
   ```

2. Check if pods are ready:
   ```bash
   kubectl get pods -n staging
   kubectl get pods -n production
   ```

3. Use port-forward as alternative:
   ```bash
   # Staging
   kubectl port-forward -n staging svc/staging-nodejs-app 30690:80
   
   # Production
   kubectl port-forward -n production svc/production-nodejs-app 30699:80
   ```

### Connection refused

1. Verify the service type:
   ```bash
   kubectl get service staging-nodejs-app -n staging -o yaml | grep type
   kubectl get service production-nodejs-app -n production -o yaml | grep type
   ```
   
   Should show: `type: NodePort`

2. Check NodePort values:
   ```bash
   kubectl get service staging-nodejs-app -n staging -o jsonpath='{.spec.ports[0].nodePort}'
   kubectl get service production-nodejs-app -n production -o jsonpath='{.spec.ports[0].nodePort}'
   ```
   
   Should show: 30690 and 30699

### Pods not ready

```bash
# Check pod status
kubectl get pods -n staging
kubectl get pods -n production

# View logs
kubectl logs -n staging deployment/staging-nodejs-app
kubectl logs -n production deployment/production-nodejs-app
```

---

## Summary

✅ **Staging**: http://localhost:30690  
✅ **Production**: http://localhost:30699

Both environments are now accessible directly from your browser with no additional configuration needed!

Just open the URLs above and you'll see your application running in both environments.
