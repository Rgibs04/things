#!/bin/bash

# ClassDojo Debit System - Raspberry Pi 3B Automated Setup Script
# For Debian-based systems (Raspberry Pi OS)
# This script installs all dependencies and deploys the application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="classdojo-debit-system"
APP_DIR="/opt/classdojo"
K3S_VERSION="v1.28.5+k3s1"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ClassDojo Debit System${NC}"
echo -e "${GREEN}Raspberry Pi 3B Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo -e "${YELLOW}Warning: This doesn't appear to be a Raspberry Pi${NC}"
    echo -e "${YELLOW}Continuing anyway...${NC}"
    echo ""
fi

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
    echo -e "Please run: ${YELLOW}sudo bash raspberry-pi-setup.sh${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1/8: Updating system packages...${NC}"
apt-get update
apt-get upgrade -y
echo -e "${GREEN}✓ System updated${NC}"
echo ""

echo -e "${BLUE}Step 2/8: Installing required packages...${NC}"
apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    python3-venv \
    sqlite3 \
    ca-certificates \
    gnupg \
    lsb-release
echo -e "${GREEN}✓ Required packages installed${NC}"
echo ""

echo -e "${BLUE}Step 3/8: Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    # Install Docker for ARM
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker pi 2>/dev/null || true
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi
echo ""

echo -e "${BLUE}Step 4/8: Installing K3s (Lightweight Kubernetes)...${NC}"
if ! command -v k3s &> /dev/null; then
    # Install K3s for ARM
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} sh -s - \
        --write-kubeconfig-mode 644 \
        --disable traefik \
        --disable servicelb
    
    # Wait for K3s to be ready
    echo -e "${YELLOW}Waiting for K3s to be ready...${NC}"
    sleep 30
    
    # Set up kubectl alias
    echo "alias kubectl='k3s kubectl'" >> /home/pi/.bashrc
    
    echo -e "${GREEN}✓ K3s installed${NC}"
else
    echo -e "${GREEN}✓ K3s already installed${NC}"
fi
echo ""

echo -e "${BLUE}Step 5/8: Setting up application directory...${NC}"
mkdir -p ${APP_DIR}
cd ${APP_DIR}

# Copy application files if running from source directory
if [ -f "$(dirname $0)/requirements.txt" ]; then
    echo -e "${YELLOW}Copying application files...${NC}"
    cp -r "$(dirname $0)"/* ${APP_DIR}/
    echo -e "${GREEN}✓ Application files copied${NC}"
else
    echo -e "${YELLOW}Please ensure application files are in ${APP_DIR}${NC}"
fi
echo ""

echo -e "${BLUE}Step 6/8: Building Docker image for ARM...${NC}"
if [ -f "${APP_DIR}/Dockerfile.arm" ]; then
    # Build using ARM-specific Dockerfile
    docker build -f ${APP_DIR}/Dockerfile.arm -t ${APP_NAME}:latest ${APP_DIR}
    echo -e "${GREEN}✓ Docker image built for ARM${NC}"
elif [ -f "${APP_DIR}/Dockerfile" ]; then
    # Fallback to regular Dockerfile with ARM platform
    docker build --platform linux/arm/v7 -t ${APP_NAME}:latest ${APP_DIR}
    echo -e "${GREEN}✓ Docker image built for ARM${NC}"
else
    echo -e "${RED}Error: Dockerfile not found in ${APP_DIR}${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}Step 7/8: Generating secure secret key...${NC}"
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
echo -e "${GREEN}✓ Secret key generated${NC}"
echo ""

# Update secret.yaml with generated key
if [ -f "${APP_DIR}/k8s/secret.yaml" ]; then
    sed -i "s/change-this-to-a-secure-random-key-in-production/${SECRET_KEY}/" ${APP_DIR}/k8s/secret.yaml
    echo -e "${GREEN}✓ Secret key updated in configuration${NC}"
fi
echo ""

echo -e "${BLUE}Step 8/8: Deploying to K3s...${NC}"
if [ -d "${APP_DIR}/k8s" ]; then
    # Import image to K3s
    docker save ${APP_NAME}:latest | k3s ctr images import -
    
    # Apply Kubernetes manifests
    k3s kubectl apply -f ${APP_DIR}/k8s/namespace.yaml
    k3s kubectl apply -f ${APP_DIR}/k8s/configmap.yaml
    k3s kubectl apply -f ${APP_DIR}/k8s/secret.yaml
    k3s kubectl apply -f ${APP_DIR}/k8s/persistent-volume.yaml
    k3s kubectl apply -f ${APP_DIR}/k8s/persistent-volume-claim.yaml
    k3s kubectl apply -f ${APP_DIR}/k8s/deployment.yaml
    k3s kubectl apply -f ${APP_DIR}/k8s/service.yaml
    
    echo -e "${GREEN}✓ Application deployed${NC}"
    echo ""
    
    # Wait for deployment to be ready
    echo -e "${YELLOW}Waiting for application to be ready...${NC}"
    k3s kubectl wait --for=condition=available --timeout=300s deployment/classdojo-debit-system -n classdojo-system
    echo -e "${GREEN}✓ Application is ready${NC}"
else
    echo -e "${RED}Error: k8s directory not found${NC}"
    exit 1
fi
echo ""

# Get the Raspberry Pi's IP address
PI_IP=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Access Information:${NC}"
echo -e "  Local access: ${GREEN}http://localhost:5000${NC}"
echo -e "  Network access: ${GREEN}http://${PI_IP}:5000${NC}"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo -e "  View pods: ${BLUE}sudo k3s kubectl get pods -n classdojo-system${NC}"
echo -e "  View logs: ${BLUE}sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system${NC}"
echo -e "  Port forward: ${BLUE}sudo k3s kubectl port-forward -n classdojo-system svc/classdojo-service 5000:80${NC}"
echo -e "  Restart app: ${BLUE}sudo k3s kubectl rollout restart deployment/classdojo-debit-system -n classdojo-system${NC}"
echo ""
echo -e "${YELLOW}Service Management:${NC}"
echo -e "  Stop K3s: ${BLUE}sudo systemctl stop k3s${NC}"
echo -e "  Start K3s: ${BLUE}sudo systemctl start k3s${NC}"
echo -e "  K3s status: ${BLUE}sudo systemctl status k3s${NC}"
echo ""
echo -e "${YELLOW}Your generated secret key has been saved to:${NC}"
echo -e "  ${APP_DIR}/k8s/secret.yaml"
echo ""
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${YELLOW}Note: You may need to reboot for all changes to take effect.${NC}"
echo ""

# Create a simple access script
cat > /usr/local/bin/classdojo-access << 'EOF'
#!/bin/bash
PI_IP=$(hostname -I | awk '{print $1}')
echo "ClassDojo Debit System Access:"
echo "  Local: http://localhost:5000"
echo "  Network: http://${PI_IP}:5000"
echo ""
echo "To port-forward (if needed):"
echo "  sudo k3s kubectl port-forward -n classdojo-system svc/classdojo-service 5000:80"
EOF

chmod +x /usr/local/bin/classdojo-access

echo -e "${GREEN}Tip: Run '${BLUE}classdojo-access${GREEN}' anytime to see access information${NC}"
