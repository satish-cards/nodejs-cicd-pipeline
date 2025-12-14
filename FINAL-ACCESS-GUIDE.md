# Final Access Guide - Staging & Production

## ✅ Services Successfully Configured!

Both staging and production are now exposed as **NodePort** services:

- **Staging**: Port 30690
- **Production**: Port 30699

---

## 🌐 How to Access

### On Docker Desktop (Mac/Windows)

NodePort services on Docker Desktop require port-forwarding to access from localhost:

```bash
# Terminal 1: Forward Staging
kubectl port-forward -n staging svc/staging-nodejs-app 30690:80

# Terminal 2: Forward Production  
kubectl port-forward -n production svc/production-nodejs-app 30699:80
```

Then access in your browser:
- **Staging**: http://localhost:30690/health
- **Production**: http://localhost:30699/health

### On Linux / Minikube / Cloud

NodePort services work directly:
- **Staging**: http://localhost:30690/health
- **Production**: http://localhost:30699/health

---

## 📋 Quick Access URLs

### Staging (Port 30690)
- Health: http://localhost:30690/health
- Users: http://localhost:30690/api/users
- Data: http://localhost:30690/api/data

### Production (Port 30699)
- Health: http://localhost:30699/health
- Users: http://localhost:30699/api/users
- Data: http://localhost:30699/api/data

---

## ✅ Verification

Check that services are NodePort:

```bash
kubectl get services -n staging
kubectl get services -n production
```

Expected output:
```
NAME                 TYPE       PORT(S)        
staging-nodejs-app   NodePort   80:30690/TCP
production-nodejs-app NodePort  80:30699/TCP
```

---

## 🎯 Summary

✅ **Staging**: NodePort on 30690  
✅ **Production**: NodePort on 30699  
✅ **Configuration**: Committed to Git  
✅ **ArgoCD**: Will sync automatically  

**Access Method**: Use port-forward on Docker Desktop, or direct access on Linux/Cloud.

---

## Files Modified

- `k8s/overlays/staging/service-patch.yaml` - NodePort configuration
- `k8s/overlays/staging/kustomization.yaml` - Added service patch
- `k8s/overlays/production/service-patch.yaml` - NodePort configuration
- `k8s/overlays/production/kustomization.yaml` - Added service patch

All changes committed to Git!
