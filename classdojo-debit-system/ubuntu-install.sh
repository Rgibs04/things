#!/bin/bash

# ClassDojo Debit System - Ubuntu 24.04 LTS Installation Script
# Optimized for Ubuntu/Debian x86_64 systems (including WSL)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/opt/classdojo"
INSTALL_METHOD=""

# Banner
clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ClassDojo Debit System - Ubuntu 24.04 LTS Installer    ║
║                                                           ║
║   Automated Setup for Ubuntu/Debian x86_64               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
    echo -e "Please run: ${YELLOW}sudo bash ubuntu-install.sh${NC}"
    exit 1
fi

# Detect system information
echo -e "${BLUE}Detecting system information...${NC}"
OS_NAME=$(grep ^NAME /etc/os-release | cut -d'"' -f2)
OS_VERSION=$(grep ^VERSION_ID /etc/os-release | cut -d'"' -f2)
ARCH=$(uname -m)
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
TOTAL_DISK=$(df -BG / | awk 'NR==2 {print $2}' | sed 's/G//')

echo -e "  OS: ${GREEN}${OS_NAME} ${OS_VERSION}${NC}"
echo -e "  Architecture: ${GREEN}${ARCH}${NC}"
echo -e "  RAM: ${GREEN}${TOTAL_RAM}MB${NC}"
echo -e "  Disk Space: ${GREEN}${TOTAL_DISK}GB${NC}"

# Check if WSL
if grep -qi microsoft /proc/version; then
    echo -e "  Environment: ${GREEN}WSL (Windows Subsystem for Linux)${NC}"
    IS_WSL=true
else
    echo -e "  Environment: ${GREEN}Native Linux${NC}"
    IS_WSL=false
fi
echo ""

# Pre-flight checks
echo -e "${BLUE}Running pre-flight checks...${NC}"

# Check RAM (minimum 512MB)
if [ "$TOTAL_RAM" -lt 512 ]; then
    echo -e "${RED}✗ Insufficient RAM: ${TOTAL_RAM}MB (minimum 512MB required)${NC}"
    exit 1
fi
echo -e "${GREEN}✓ RAM check passed (${TOTAL_RAM}MB)${NC}"

# Check disk space (minimum 2GB free)
FREE_DISK=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$FREE_DISK" -lt 2 ]; then
    echo -e "${RED}✗ Insufficient disk space: ${FREE_DISK}GB free (minimum 2GB required)${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Disk space check passed (${FREE_DISK}GB free)${NC}"

# Check architecture (x86_64 or aarch64)
if [[ ! "$ARCH" =~ ^(x86_64|aarch64)$ ]]; then
    echo -e "${YELLOW}⚠ Warning: Architecture ${ARCH} may not be fully supported${NC}"
fi
echo -e "${GREEN}✓ Architecture check passed (${ARCH})${NC}"

# Check internet connectivity
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${RED}✗ No internet connection detected${NC}"
    echo -e "${RED}  Please connect to the internet and try again${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Internet connectivity check passed${NC}"
echo ""

# Ask for installation method
echo -e "${CYAN}Choose installation method:${NC}"
echo -e "  ${GREEN}1)${NC} Docker Compose - Recommended for most users ⭐"
echo -e "     • Easy management with simple commands"
echo -e "     • Automatic restarts and health checks"
echo -e "     • ~200MB RAM, 1.5GB disk"
echo ""
echo -e "  ${GREEN}2)${NC} Standalone Python - Minimal resources"
echo -e "     • Direct Python execution, no containers"
echo -e "     • Systemd service management"
echo -e "     • ~100MB RAM, 500MB disk"
echo ""
echo -e "  ${GREEN}3)${NC} K3s (Kubernetes) - Production ready"
echo -e "     • Full orchestration and auto-healing"
echo -e "     • Best for scalability"
echo -e "     • ~400MB RAM, 2GB disk"
echo ""
read -p "Enter choice [1-3] (default: 1): " INSTALL_METHOD
INSTALL_METHOD=${INSTALL_METHOD:-1}

# Confirm installation
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Installation Summary:${NC}"
echo -e "  Installation directory: ${CYAN}${APP_DIR}${NC}"
echo -e "  Method: ${CYAN}$([ "$INSTALL_METHOD" = "1" ] && echo "Docker Compose" || ([ "$INSTALL_METHOD" = "2" ] && echo "Standalone Python" || echo "K3s (Kubernetes)"))${NC}"
echo -e "  Estimated time: ${CYAN}10-20 minutes${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
read -p "Proceed with installation? (Y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    exit 0
fi

# Update system
echo ""
echo -e "${BLUE}Step 1: Updating system packages...${NC}"
apt-get update -qq
apt-get upgrade -y -qq
echo -e "${GREEN}✓ System updated${NC}"
echo ""

# Install based on method
case $INSTALL_METHOD in
    1)
        # Docker Compose Installation
        echo -e "${BLUE}Step 2: Installing Docker Compose method...${NC}"
        echo ""
        
        echo -e "${BLUE}  Installing required packages...${NC}"
        apt-get install -y -qq curl git python3 python3-pip python3-venv sqlite3 ca-certificates
        echo -e "${GREEN}  ✓ Required packages installed${NC}"
        
        echo -e "${BLUE}  Installing Docker...${NC}"
        if ! command -v docker &> /dev/null; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh > /dev/null 2>&1
            rm get-docker.sh
            systemctl enable docker > /dev/null 2>&1 || true
            systemctl start docker > /dev/null 2>&1 || true
            echo -e "${GREEN}  ✓ Docker installed${NC}"
        else
            echo -e "${GREEN}  ✓ Docker already installed${NC}"
        fi
        
        echo -e "${BLUE}  Installing Docker Compose...${NC}"
        if ! command -v docker-compose &> /dev/null; then
            apt-get install -y -qq docker-compose-plugin || pip3 install docker-compose
            echo -e "${GREEN}  ✓ Docker Compose installed${NC}"
        else
            echo -e "${GREEN}  ✓ Docker Compose already installed${NC}"
        fi
        
        echo -e "${BLUE}  Setting up application...${NC}"
        mkdir -p ${APP_DIR}
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cp -r "${SCRIPT_DIR}"/* ${APP_DIR}/ 2>/dev/null || true
        cd ${APP_DIR}
        
        # Generate secret key
        SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
        
        # Create Docker Compose file for x86_64
        cat > ${APP_DIR}/docker-compose.yml <<'EOF'
version: '3.8'

services:
  classdojo-app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: classdojo-debit-system
    ports:
      - "5000:5000"
    environment:
      - SECRET_KEY=${SECRET_KEY}
      - FLASK_ENV=production
    volumes:
      - ./database:/app/database
      - ./src:/app/src
      - ./templates:/app/templates
      - ./static:/app/static
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:5000/health').read()"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
EOF
        
        echo "SECRET_KEY=${SECRET_KEY}" > ${APP_DIR}/.env
        echo -e "${GREEN}  ✓ Configuration created${NC}"
        
        echo -e "${BLUE}  Building and starting application...${NC}"
        docker-compose up -d --build
        
        sleep 10
        
        if docker ps | grep -q classdojo-debit-system; then
            echo -e "${GREEN}  ✓ Application is running${NC}"
        else
            echo -e "${RED}  ✗ Application failed to start${NC}"
            docker-compose logs
            exit 1
        fi
        
        # Create management script
        cat > /usr/local/bin/classdojo-manage << 'MANAGE_EOF'
#!/bin/bash
APP_DIR="/opt/classdojo"
cd ${APP_DIR}

case "$1" in
    start) docker-compose up -d ;;
    stop) docker-compose down ;;
    restart) docker-compose restart ;;
    logs) docker-compose logs -f ;;
    status) docker-compose ps ;;
    backup)
        BACKUP_FILE="${HOME}/classdojo-backup-$(date +%Y%m%d-%H%M%S).db"
        docker cp classdojo-debit-system:/app/database/school_debit.db "${BACKUP_FILE}"
        echo "Database backed up to: ${BACKUP_FILE}"
        ;;
    access)
        echo "ClassDojo Debit System Access:"
        echo "  Local: http://localhost:5000"
        echo "  Network: http://$(hostname -I | awk '{print $1}'):5000"
        ;;
    *)
        echo "Usage: classdojo-manage {start|stop|restart|logs|status|backup|access}"
        ;;
esac
MANAGE_EOF
        chmod +x /usr/local/bin/classdojo-manage
        
        # Create systemd service for Docker Compose auto-start
        cat > /etc/systemd/system/classdojo-docker.service <<'SERVICE_EOF'
[Unit]
Description=ClassDojo Debit System (Docker Compose)
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/classdojo
ExecStart=/usr/bin/docker-compose -f /opt/classdojo/docker-compose.yml up -d
ExecStop=/usr/bin/docker-compose -f /opt/classdojo/docker-compose.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SERVICE_EOF
        
        # Enable the service for auto-start
        systemctl daemon-reload
        systemctl enable classdojo-docker.service > /dev/null 2>&1
        echo -e "${GREEN}  ✓ Auto-start configured${NC}"
        
        MGMT_CMD="classdojo-manage"
        ;;
        
    2)
        # Standalone Python Installation
        echo -e "${BLUE}Step 2: Installing Standalone Python method...${NC}"
        echo ""
        
        echo -e "${BLUE}  Installing Python dependencies...${NC}"
        apt-get install -y -qq python3 python3-pip python3-venv sqlite3
        echo -e "${GREEN}  ✓ Python dependencies installed${NC}"
        
        echo -e "${BLUE}  Setting up application...${NC}"
        mkdir -p ${APP_DIR}
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cp -r "${SCRIPT_DIR}"/* ${APP_DIR}/ 2>/dev/null || true
        cd ${APP_DIR}
        
        python3 -m venv venv
        source venv/bin/activate
        pip install -q -r requirements.txt
        
        SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
        
        # Create systemd service
        cat > /etc/systemd/system/classdojo.service <<EOF
[Unit]
Description=ClassDojo Debit System
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${APP_DIR}
Environment="SECRET_KEY=${SECRET_KEY}"
Environment="FLASK_ENV=production"
ExecStart=${APP_DIR}/venv/bin/python src/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        systemctl enable classdojo
        systemctl start classdojo
        
        sleep 5
        
        if systemctl is-active --quiet classdojo; then
            echo -e "${GREEN}  ✓ Application is running${NC}"
        else
            echo -e "${RED}  ✗ Application failed to start${NC}"
            journalctl -u classdojo -n 50
            exit 1
        fi
        
        MGMT_CMD="systemctl"
        ;;
        
    3)
        # K3s Installation
        echo -e "${BLUE}Step 2: Installing K3s method...${NC}"
        echo ""
        
        echo -e "${BLUE}  Installing required packages...${NC}"
        apt-get install -y -qq curl git python3 python3-pip sqlite3 ca-certificates
        echo -e "${GREEN}  ✓ Required packages installed${NC}"
        
        echo -e "${BLUE}  Installing Docker...${NC}"
        if ! command -v docker &> /dev/null; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh > /dev/null 2>&1
            rm get-docker.sh
            echo -e "${GREEN}  ✓ Docker installed${NC}"
        else
            echo -e "${GREEN}  ✓ Docker already installed${NC}"
        fi
        
        echo -e "${BLUE}  Installing K3s...${NC}"
        if ! command -v k3s &> /dev/null; then
            curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --disable traefik --disable servicelb
            sleep 30
            echo -e "${GREEN}  ✓ K3s installed${NC}"
        else
            echo -e "${GREEN}  ✓ K3s already installed${NC}"
        fi
        
        echo -e "${BLUE}  Setting up application...${NC}"
        mkdir -p ${APP_DIR}
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cp -r "${SCRIPT_DIR}"/* ${APP_DIR}/ 2>/dev/null || true
        cd ${APP_DIR}
        
        docker build -t classdojo-debit-system:latest .
        docker save classdojo-debit-system:latest | k3s ctr images import -
        
        SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
        sed -i "s/change-this-to-a-secure-random-key-in-production/${SECRET_KEY}/" ${APP_DIR}/k8s/secret.yaml
        
        k3s kubectl apply -f ${APP_DIR}/k8s/
        
        echo -e "${YELLOW}  Waiting for application to be ready...${NC}"
        k3s kubectl wait --for=condition=available --timeout=300s deployment/classdojo-debit-system -n classdojo-system
        echo -e "${GREEN}  ✓ Application is running${NC}"
        
        MGMT_CMD="k3s kubectl"
        ;;
esac

# Get IP address
IP_ADDR=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║   Installation completed successfully! 🎉                ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Access Information:${NC}"
echo -e "  Local: ${GREEN}http://localhost:5000${NC}"
echo -e "  Network: ${GREEN}http://${IP_ADDR}:5000${NC}"
echo ""
echo -e "${CYAN}Auto-Start:${NC}"
echo -e "  ✅ Application will ${GREEN}automatically start on system boot${NC}"
echo ""

case $INSTALL_METHOD in
    1)
        echo -e "${CYAN}Management Commands:${NC}"
        echo -e "  Start: ${BLUE}classdojo-manage start${NC}"
        echo -e "  Stop: ${BLUE}classdojo-manage stop${NC}"
        echo -e "  Restart: ${BLUE}classdojo-manage restart${NC}"
        echo -e "  Logs: ${BLUE}classdojo-manage logs${NC}"
        echo -e "  Status: ${BLUE}classdojo-manage status${NC}"
        echo -e "  Backup: ${BLUE}classdojo-manage backup${NC}"
        ;;
    2)
        echo -e "${CYAN}Management Commands:${NC}"
        echo -e "  Start: ${BLUE}sudo systemctl start classdojo${NC}"
        echo -e "  Stop: ${BLUE}sudo systemctl stop classdojo${NC}"
        echo -e "  Restart: ${BLUE}sudo systemctl restart classdojo${NC}"
        echo -e "  Logs: ${BLUE}sudo journalctl -u classdojo -f${NC}"
        echo -e "  Status: ${BLUE}sudo systemctl status classdojo${NC}"
        ;;
    3)
        echo -e "${CYAN}Management Commands:${NC}"
        echo -e "  Pods: ${BLUE}sudo k3s kubectl get pods -n classdojo-system${NC}"
        echo -e "  Logs: ${BLUE}sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system -f${NC}"
        echo -e "  Restart: ${BLUE}sudo k3s kubectl rollout restart deployment/classdojo-debit-system -n classdojo-system${NC}"
        ;;
esac

echo ""
echo -e "${GREEN}Thank you for using ClassDojo Debit System!${NC}"
echo ""
