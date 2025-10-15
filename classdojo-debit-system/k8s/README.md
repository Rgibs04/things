# Kubernetes Deployment Guide for ClassDojo Debit System

This guide will help you deploy the ClassDojo Debit System to a Kubernetes cluster.

## Prerequisites

- Kubernetes cluster (minikube, Docker Desktop, EKS, GKE, AKS, etc.)
- `kubectl` CLI tool installed and configured
- Docker installed (for building the image)
- Access to a container registry (Docker Hub, ECR, GCR, etc.) - optional for local testing

## Quick Start

### 1. Build the Docker Image

```bash
# Navigate to the project directory
cd classdojo-debit-system

# Build the Docker image
docker build -t classdojo-debit-system:latest .

# For local Kubernetes (minikube), load the image
# minikube image load classdojo-debit-system:latest

# For remote registry, tag and push
# docker tag classdojo-debit-system:latest your-registry/classdojo-debit-system:latest
# docker push your-registry/classdojo-debit-system:latest
```

### 2. Update Secret Key (IMPORTANT!)

Before deploying, generate a secure secret key:

```bash
# Generate a secure random key
python -c "import secrets; print(secrets.token_hex(32))"
```

Edit `k8s/secret.yaml` and replace the `SECRET_KEY` value with your generated key.

### 3. Deploy to Kubernetes

```bash
# Apply all Kubernetes manifests in order
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/persistent-volume.yaml
kubectl apply -f k8s/persistent-volume-claim.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Optional: Apply ingress if you have an ingress controller
kubectl apply -f k8s/ingress.yaml
```

Or apply all at once:

```bash
kubectl apply -f k8s/
```

### 4. Verify Deployment

```bash
# Check if all resources are created
kubectl get all -n classdojo-system

# Check pod status
kubectl get pods -n classdojo-system

# Check pod logs
kubectl logs -n classdojo-system -l app=classdojo-debit-system

# Check service
kubectl get svc -n classdojo-system
```

### 5. Access the Application

#### Option A: Using LoadBalancer (Cloud providers)

```bash
# Get the external IP
kubectl get svc classdojo-service -n classdojo-system

# Access via: http://<EXTERNAL-IP>
```

#### Option B: Using NodePort (Local/Minikube)

```bash
# Change service type to NodePort in k8s/service.yaml
# Then get the node port
kubectl get svc classdojo-service -n classdojo-system

# For minikube
minikube service classdojo-service -n classdojo-system
```

#### Option C: Using Port Forward (Development)

```bash
# Forward local port to the service
kubectl port-forward -n classdojo-system svc/classdojo-service 5000:80

# Access via: http://localhost:5000
```

#### Option D: Using Ingress

If you have an ingress controller installed:

```bash
# Update the host in k8s/ingress.yaml
# Add the host to your /etc/hosts file (for local testing)
# Access via: http://classdojo.local
```

## Configuration

### Environment Variables

Edit `k8s/configmap.yaml` to modify:
- `FLASK_ENV`: Set to "production" for production deployment
- `DATABASE_PATH`: Path to the SQLite database file

### Secrets

Edit `k8s/secret.yaml` to modify:
- `SECRET_KEY`: Flask secret key for session management

### Resource Limits

Edit `k8s/deployment.yaml` to adjust:
- `replicas`: Number of pod replicas (default: 1)
- `resources.requests`: Minimum resources guaranteed
- `resources.limits`: Maximum resources allowed

### Storage

Edit `k8s/persistent-volume.yaml` to modify:
- `capacity.storage`: Storage size (default: 1Gi)
- `hostPath.path`: Path on the host for local storage

For cloud providers, you may want to use dynamic provisioning instead:

```yaml
# Remove persistent-volume.yaml
# Update persistent-volume-claim.yaml to use a StorageClass
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: classdojo-pvc
  namespace: classdojo-system
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard  # or gp2, pd-standard, etc.
  resources:
    requests:
      storage: 1Gi
```

## Scaling

### Horizontal Scaling

**Note**: This application uses SQLite, which doesn't support multiple writers. For horizontal scaling, consider:

1. Using a shared database (PostgreSQL, MySQL)
2. Using ReadWriteMany storage
3. Implementing a database connection pool

To scale (with limitations):

```bash
kubectl scale deployment classdojo-debit-system -n classdojo-system --replicas=3
```

### Vertical Scaling

Update resource limits in `k8s/deployment.yaml`:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

## Monitoring

### Health Checks

The application includes a `/health` endpoint for Kubernetes probes:

```bash
# Check health endpoint
kubectl exec -n classdojo-system -it <pod-name> -- curl http://localhost:5000/health
```

### Logs

```bash
# View logs
kubectl logs -n classdojo-system -l app=classdojo-debit-system

# Follow logs
kubectl logs -n classdojo-system -l app=classdojo-debit-system -f

# View logs from all pods
kubectl logs -n classdojo-system -l app=classdojo-debit-system --all-containers=true
```

### Events

```bash
# View events
kubectl get events -n classdojo-system --sort-by='.lastTimestamp'
```

## Backup and Restore

### Backup Database

```bash
# Get the pod name
POD_NAME=$(kubectl get pods -n classdojo-system -l app=classdojo-debit-system -o jsonpath='{.items[0].metadata.name}')

# Copy database from pod
kubectl cp classdojo-system/$POD_NAME:/app/database/school_debit.db ./backup-$(date +%Y%m%d).db
```

### Restore Database

```bash
# Copy database to pod
kubectl cp ./backup.db classdojo-system/$POD_NAME:/app/database/school_debit.db

# Restart the pod to reload
kubectl rollout restart deployment classdojo-debit-system -n classdojo-system
```

## Updating the Application

### Rolling Update

```bash
# Build new image with a version tag
docker build -t classdojo-debit-system:v2.0 .

# Push to registry (if using remote registry)
docker push your-registry/classdojo-debit-system:v2.0

# Update deployment
kubectl set image deployment/classdojo-debit-system -n classdojo-system \
  classdojo-app=classdojo-debit-system:v2.0

# Check rollout status
kubectl rollout status deployment/classdojo-debit-system -n classdojo-system
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/classdojo-debit-system -n classdojo-system

# Rollback to specific revision
kubectl rollout undo deployment/classdojo-debit-system -n classdojo-system --to-revision=2
```

## Troubleshooting

### Pod Not Starting

```bash
# Describe pod to see events
kubectl describe pod -n classdojo-system -l app=classdojo-debit-system

# Check logs
kubectl logs -n classdojo-system -l app=classdojo-debit-system
```

### Database Issues

```bash
# Check if PVC is bound
kubectl get pvc -n classdojo-system

# Check if PV exists
kubectl get pv

# Exec into pod to check database
kubectl exec -n classdojo-system -it <pod-name> -- ls -la /app/database/
```

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n classdojo-system

# Check if pods are ready
kubectl get pods -n classdojo-system

# Test from within cluster
kubectl run -n classdojo-system test-pod --image=curlimages/curl --rm -it -- curl http://classdojo-service/health
```

## Cleanup

To remove all resources:

```bash
# Delete all resources in the namespace
kubectl delete namespace classdojo-system

# Or delete individual resources
kubectl delete -f k8s/
```

## Production Considerations

1. **Database**: Consider migrating to PostgreSQL or MySQL for production
2. **Secrets Management**: Use external secret management (Vault, AWS Secrets Manager, etc.)
3. **SSL/TLS**: Configure ingress with SSL certificates
4. **Monitoring**: Set up Prometheus and Grafana for monitoring
5. **Logging**: Configure centralized logging (ELK, Loki, etc.)
6. **Backup**: Implement automated backup solutions
7. **High Availability**: Use multiple replicas with proper database setup
8. **Security**: Implement network policies, pod security policies, and RBAC

## Support

For issues or questions, refer to the main README.md or contact your system administrator.
