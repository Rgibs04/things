#!/bin/bash

# ClassDojo Debit System - Kubernetes Deployment Script
# This script automates the deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="classdojo-debit-system"
IMAGE_TAG="latest"
NAMESPACE="classdojo-system"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ClassDojo Debit System - K8s Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command_exists kubectl; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

if ! command_exists docker; then
    echo -e "${RED}Error: docker is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"
echo ""

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
cd ..
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
echo -e "${GREEN}✓ Docker image built successfully${NC}"
echo ""

# Check if using minikube
if command_exists minikube && minikube status >/dev/null 2>&1; then
    echo -e "${YELLOW}Detected minikube, loading image...${NC}"
    minikube image load ${IMAGE_NAME}:${IMAGE_TAG}
    echo -e "${GREEN}✓ Image loaded to minikube${NC}"
    echo ""
fi

# Deploy to Kubernetes
echo -e "${YELLOW}Deploying to Kubernetes...${NC}"
cd k8s

# Apply manifests in order
kubectl apply -f namespace.yaml
echo -e "${GREEN}✓ Namespace created${NC}"

kubectl apply -f configmap.yaml
echo -e "${GREEN}✓ ConfigMap created${NC}"

kubectl apply -f secret.yaml
echo -e "${GREEN}✓ Secret created${NC}"

kubectl apply -f persistent-volume.yaml
echo -e "${GREEN}✓ PersistentVolume created${NC}"

kubectl apply -f persistent-volume-claim.yaml
echo -e "${GREEN}✓ PersistentVolumeClaim created${NC}"

kubectl apply -f deployment.yaml
echo -e "${GREEN}✓ Deployment created${NC}"

kubectl apply -f service.yaml
echo -e "${GREEN}✓ Service created${NC}"

echo ""
echo -e "${YELLOW}Waiting for deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/classdojo-debit-system -n ${NAMESPACE}
echo -e "${GREEN}✓ Deployment is ready${NC}"
echo ""

# Display status
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Status${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo -e "${YELLOW}Pods:${NC}"
kubectl get pods -n ${NAMESPACE}
echo ""

echo -e "${YELLOW}Services:${NC}"
kubectl get svc -n ${NAMESPACE}
echo ""

# Get access information
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Access Information${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if command_exists minikube && minikube status >/dev/null 2>&1; then
    echo -e "${YELLOW}To access the application, run:${NC}"
    echo -e "  minikube service classdojo-service -n ${NAMESPACE}"
else
    SERVICE_TYPE=$(kubectl get svc classdojo-service -n ${NAMESPACE} -o jsonpath='{.spec.type}')
    
    if [ "$SERVICE_TYPE" = "LoadBalancer" ]; then
        echo -e "${YELLOW}Waiting for LoadBalancer IP...${NC}"
        EXTERNAL_IP=""
        while [ -z $EXTERNAL_IP ]; do
            EXTERNAL_IP=$(kubectl get svc classdojo-service -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
            [ -z "$EXTERNAL_IP" ] && sleep 5
        done
        echo -e "${GREEN}Application is accessible at: http://${EXTERNAL_IP}${NC}"
    else
        echo -e "${YELLOW}To access the application, run:${NC}"
        echo -e "  kubectl port-forward -n ${NAMESPACE} svc/classdojo-service 5000:80"
        echo -e "  Then access: http://localhost:5000"
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
