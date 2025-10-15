# ClassDojo Debit System - Deployment Guide

This guide covers multiple deployment options for the ClassDojo Debit System.

## Table of Contents

1. [Local Development](#local-development)
2. [Docker Deployment](#docker-deployment)
3. [Kubernetes Deployment](#kubernetes-deployment)
4. [Cloud Deployment](#cloud-deployment)

---

## Local Development

### Prerequisites
- Python 3.7 or higher
- pip (Python package manager)

### Setup

1. Navigate to the project directory:
   ```bash
   cd classdojo-debit-system
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run the application:
   ```bash
   python src/app.py
   ```

4. Access the application at: `http://localhost:5000`

---

## Docker Deployment

### Using Docker Compose (Recommended for Local Testing)

1. Build and run with Docker Compose:
   ```bash
   docker-compose up -d
   ```

2. Access the application at: `http://localhost:5000`

3. View logs:
   ```bash
   docker-compose logs -f
   ```

4. Stop the application:
   ```bash
   docker-compose down
   ```

### Using Docker Directly

1. Build the Docker image:
   ```bash
   docker build -t classdojo-debit-system:latest .
   ```

2. Run the container:
   ```bash
   docker run -d \
     -p 5000:5000 \
     -v $(pwd)/database:/app/database \
     -e SECRET_KEY=your-secret-key-here \
     --name classdojo-app \
     classdojo-debit-system:latest
   ```

3. Access the application at: `http://localhost:5000`

4. View logs:
   ```bash
   docker logs -f classdojo-app
   ```

5. Stop and remove:
   ```bash
   docker stop classdojo-app
   docker rm classdojo-app
   ```

---

## Kubernetes Deployment

### Prerequisites
- Kubernetes cluster (minikube, Docker Desktop, EKS, GKE, AKS, etc.)
- kubectl CLI tool installed and configured
- Docker installed

### Quick Deployment

#### Option 1: Using Deployment Scripts

**For Linux/Mac:**
```bash
cd k8s
chmod +x deploy.sh
./deploy.sh
```

**For Windows:**
```cmd
cd k8s
deploy.bat
```

#### Option 2: Manual Deployment

1. **Build and Load Docker Image:**
   ```bash
   # Build the image
   docker build -t classdojo-debit-system:latest .
   
   # For minikube
   minikube image load classdojo-debit-system:latest
   
   # For remote registry
   docker tag classdojo-debit-system:latest your-registry/classdojo-debit-system:latest
   docker push your-registry/classdojo-debit-system:latest
   ```

2. **Update Secret Key:**
   ```bash
   # Generate a secure key
   python -c "import secrets; print(secrets.token_hex(32))"
   
   # Edit k8s/secret.yaml and update the SECRET_KEY
   ```

3. **Deploy to Kubernetes:**
   ```bash
   # Apply all manifests
   kubectl apply -f k8s/namespace.yaml
   kubectl apply -f k8s/configmap.yaml
   kubectl apply -f k8s/secret.yaml
   kubectl apply -f k8s/persistent-volume.yaml
   kubectl apply -f k8s/persistent-volume-claim.yaml
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/service.yaml
   
   # Optional: Apply ingress
   kubectl apply -f k8s/ingress.yaml
   ```

4. **Verify Deployment:**
   ```bash
   # Check all resources
   kubectl get all -n classdojo-system
   
   # Check pod logs
   kubectl logs -n classdojo-system -l app=classdojo-debit-system
   ```

5. **Access the Application:**

   **For Minikube:**
   ```bash
   minikube service classdojo-service -n classdojo-system
   ```

   **For Port Forwarding:**
   ```bash
   kubectl port-forward -n classdojo-system svc/classdojo-service 5000:80
   # Access at: http://localhost:5000
   ```

   **For LoadBalancer:**
   ```bash
   kubectl get svc classdojo-service -n classdojo-system
   # Use the EXTERNAL-IP shown
   ```

### Detailed Kubernetes Documentation

For detailed Kubernetes deployment instructions, troubleshooting, and advanced configurations, see [k8s/README.md](k8s/README.md).

---

## Cloud Deployment

### AWS (EKS)

1. **Create EKS Cluster:**
   ```bash
   eksctl create cluster --name classdojo-cluster --region us-east-1
   ```

2. **Build and Push to ECR:**
   ```bash
   # Create ECR repository
   aws ecr create-repository --repository-name classdojo-debit-system
   
   # Login to ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
   
   # Build and push
   docker build -t classdojo-debit-system:latest .
   docker tag classdojo-debit-system:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/classdojo-debit-system:latest
   docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/classdojo-debit-system:latest
   ```

3. **Update Deployment:**
   - Edit `k8s/deployment.yaml` to use your ECR image
   - Update `k8s/persistent-volume-claim.yaml` to use EBS storage class

4. **Deploy:**
   ```bash
   kubectl apply -f k8s/
   ```

### Google Cloud (GKE)

1. **Create GKE Cluster:**
   ```bash
   gcloud container clusters create classdojo-cluster --zone us-central1-a
   ```

2. **Build and Push to GCR:**
   ```bash
   # Build and push
   docker build -t classdojo-debit-system:latest .
   docker tag classdojo-debit-system:latest gcr.io/<project-id>/classdojo-debit-system:latest
   docker push gcr.io/<project-id>/classdojo-debit-system:latest
   ```

3. **Update Deployment:**
   - Edit `k8s/deployment.yaml` to use your GCR image
   - Update `k8s/persistent-volume-claim.yaml` to use GCE storage class

4. **Deploy:**
   ```bash
   kubectl apply -f k8s/
   ```

### Azure (AKS)

1. **Create AKS Cluster:**
   ```bash
   az aks create --resource-group myResourceGroup --name classdojo-cluster --node-count 2
   ```

2. **Build and Push to ACR:**
   ```bash
   # Create ACR
   az acr create --resource-group myResourceGroup --name classdojoacr --sku Basic
   
   # Login to ACR
   az acr login --name classdojoacr
   
   # Build and push
   docker build -t classdojo-debit-system:latest .
   docker tag classdojo-debit-system:latest classdojoacr.azurecr.io/classdojo-debit-system:latest
   docker push classdojoacr.azurecr.io/classdojo-debit-system:latest
   ```

3. **Update Deployment:**
   - Edit `k8s/deployment.yaml` to use your ACR image
   - Update `k8s/persistent-volume-claim.yaml` to use Azure Disk storage class

4. **Deploy:**
   ```bash
   kubectl apply -f k8s/
   ```

---

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `SECRET_KEY` | Flask secret key for sessions | `your-secret-key-change-this` | Yes (Production) |
| `FLASK_ENV` | Flask environment mode | `development` | No |
| `DATABASE_PATH` | Path to SQLite database | `database/school_debit.db` | No |

---

## Security Considerations

### Before Production Deployment:

1. **Change Secret Key:**
   - Generate a secure random key
   - Store in Kubernetes Secret or environment variable
   - Never commit secrets to version control

2. **Enable HTTPS:**
   - Configure SSL/TLS certificates
   - Use cert-manager for automatic certificate management
   - Update ingress configuration

3. **Database Security:**
   - Consider migrating to PostgreSQL or MySQL for production
   - Enable database encryption
   - Implement regular backups

4. **Network Security:**
   - Implement Kubernetes Network Policies
   - Use private container registries
   - Enable pod security policies

5. **Access Control:**
   - Implement authentication and authorization
   - Use RBAC for Kubernetes access
   - Enable audit logging

---

## Monitoring and Logging

### Health Checks

The application includes a `/health` endpoint:
```bash
curl http://localhost:5000/health
```

### Logs

**Docker:**
```bash
docker logs -f classdojo-app
```

**Kubernetes:**
```bash
kubectl logs -n classdojo-system -l app=classdojo-debit-system -f
```

### Metrics

Consider integrating:
- Prometheus for metrics collection
- Grafana for visualization
- ELK Stack for centralized logging

---

## Backup and Restore

### Database Backup

**Docker:**
```bash
docker cp classdojo-app:/app/database/school_debit.db ./backup-$(date +%Y%m%d).db
```

**Kubernetes:**
```bash
POD_NAME=$(kubectl get pods -n classdojo-system -l app=classdojo-debit-system -o jsonpath='{.items[0].metadata.name}')
kubectl cp classdojo-system/$POD_NAME:/app/database/school_debit.db ./backup-$(date +%Y%m%d).db
```

### Database Restore

**Docker:**
```bash
docker cp ./backup.db classdojo-app:/app/database/school_debit.db
docker restart classdojo-app
```

**Kubernetes:**
```bash
kubectl cp ./backup.db classdojo-system/$POD_NAME:/app/database/school_debit.db
kubectl rollout restart deployment classdojo-debit-system -n classdojo-system
```

---

## Troubleshooting

### Common Issues

1. **Port Already in Use:**
   - Change the port mapping in docker-compose.yml or deployment
   - Kill the process using the port

2. **Database Permission Issues:**
   - Ensure proper volume permissions
   - Check pod security context

3. **Image Pull Errors:**
   - Verify image name and tag
   - Check registry credentials
   - Ensure image is pushed to registry

4. **Pod CrashLoopBackOff:**
   - Check pod logs: `kubectl logs <pod-name>`
   - Verify environment variables
   - Check resource limits

For more troubleshooting tips, see [k8s/README.md](k8s/README.md).

---

## Support

For issues or questions:
- Check the [main README.md](README.md)
- Review [k8s/README.md](k8s/README.md) for Kubernetes-specific issues
- Contact your system administrator

---

## License

This project is created for educational purposes.
