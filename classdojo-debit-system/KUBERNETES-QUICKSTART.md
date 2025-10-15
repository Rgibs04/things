# Kubernetes Quick Start Guide

Get your ClassDojo Debit System running on Kubernetes in minutes!

## Prerequisites

- ✅ Docker installed
- ✅ kubectl installed
- ✅ Kubernetes cluster running (minikube, Docker Desktop, or cloud provider)

## 🚀 Quick Deploy (3 Steps)

### Step 1: Build the Docker Image

```bash
cd classdojo-debit-system
docker build -t classdojo-debit-system:latest .
```

**For minikube users:**
```bash
minikube image load classdojo-debit-system:latest
```

### Step 2: Update Secret Key (IMPORTANT!)

Generate a secure key:
```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

Edit `k8s/secret.yaml` and replace the SECRET_KEY value with your generated key.

### Step 3: Deploy

**Option A - Automated (Recommended):**

Linux/Mac:
```bash
cd k8s
chmod +x deploy.sh
./deploy.sh
```

Windows:
```cmd
cd k8s
deploy.bat
```

**Option B - Manual:**
```bash
kubectl apply -f k8s/
```

## 🌐 Access Your Application

### For Minikube:
```bash
minikube service classdojo-service -n classdojo-system
```

### For Other Kubernetes:
```bash
kubectl port-forward -n classdojo-system svc/classdojo-service 5000:80
```
Then open: http://localhost:5000

### For Cloud LoadBalancer:
```bash
kubectl get svc classdojo-service -n classdojo-system
```
Use the EXTERNAL-IP shown.

## 📊 Check Status

```bash
# View all resources
kubectl get all -n classdojo-system

# View logs
kubectl logs -n classdojo-system -l app=classdojo-debit-system -f

# Check health
kubectl exec -n classdojo-system -it <pod-name> -- curl http://localhost:5000/health
```

## 🔄 Update Application

```bash
# Rebuild image
docker build -t classdojo-debit-system:v2 .

# For minikube
minikube image load classdojo-debit-system:v2

# Update deployment
kubectl set image deployment/classdojo-debit-system -n classdojo-system classdojo-app=classdojo-debit-system:v2

# Check rollout
kubectl rollout status deployment/classdojo-debit-system -n classdojo-system
```

## 🗑️ Clean Up

```bash
# Delete everything
kubectl delete namespace classdojo-system

# Or delete individual resources
kubectl delete -f k8s/
```

## 🆘 Troubleshooting

**Pod not starting?**
```bash
kubectl describe pod -n classdojo-system -l app=classdojo-debit-system
kubectl logs -n classdojo-system -l app=classdojo-debit-system
```

**Can't access the app?**
```bash
# Check if service is running
kubectl get svc -n classdojo-system

# Check if pods are ready
kubectl get pods -n classdojo-system
```

**Database issues?**
```bash
# Check PVC status
kubectl get pvc -n classdojo-system

# Check inside pod
kubectl exec -n classdojo-system -it <pod-name> -- ls -la /app/database/
```

## 📚 More Information

- Full Kubernetes guide: [k8s/README.md](k8s/README.md)
- Complete deployment guide: [DEPLOYMENT.md](DEPLOYMENT.md)
- Main documentation: [README.md](README.md)

## 🎯 What's Deployed?

- **Namespace:** classdojo-system
- **Deployment:** 1 replica (scalable)
- **Service:** LoadBalancer on port 80
- **Storage:** 1Gi PersistentVolume for database
- **Health Checks:** Liveness and readiness probes
- **Resources:** 128Mi-512Mi RAM, 100m-500m CPU

## 🔐 Security Reminder

Before production:
1. ✅ Change SECRET_KEY in k8s/secret.yaml
2. ✅ Enable HTTPS/TLS
3. ✅ Implement authentication
4. ✅ Use external database (PostgreSQL/MySQL)
5. ✅ Set up monitoring and backups

---

**Need help?** Check the detailed guides or contact your system administrator.
