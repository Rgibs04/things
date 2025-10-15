#!/bin/bash

# ClassDojo Debit System - Docker Compose Installation Script
# Lightweight alternative to K3s for Raspberry Pi 3B

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ClassDojo Debit System${NC}"
echo -e "${GREEN}Docker Compose Installation${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
    exit 1
fi

# Configuration
APP_DIR="/opt/classdojo"

echo -e "${BLUE}Step 1/6: Updating system packages...${NC}"
apt-get update
apt-get upgrade -y
echo -e "${GREEN}✓ System updated${NC}"
echo ""

echo -e "${BLUE}Step 2/6: Installing required packages...${NC}"
apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    sqlite3 \
    ca-certificates
echo -e "${GREEN}✓ Required packages installed${NC}"
echo ""

echo -e "${BLUE}Step 3/6: Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
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

echo -e "${BLUE}Step 4/6: Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    # Install docker-compose via pip for ARM compatibility
    pip3 install docker-compose
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✓ Docker Compose already installed${NC}"
fi
echo ""

echo -e "${BLUE}Step 5/6: Setting up application...${NC}"
mkdir -p ${APP_DIR}

# Copy application files if running from source directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/requirements.txt" ]; then
    echo -e "${YELLOW}Copying application files...${NC}"
    cp -r "${SCRIPT_DIR}"/* ${APP_DIR}/
    echo -e "${GREEN}✓ Application files copied${NC}"
else
    echo -e "${YELLOW}Please ensure application files are in ${APP_DIR}${NC}"
fi

cd ${APP_DIR}

# Generate secret key
echo -e "${BLUE}Generating secure secret key...${NC}"
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
echo -e "${GREEN}✓ Secret key generated${NC}"
echo ""

# Create Docker Compose file for Raspberry Pi
cat > ${APP_DIR}/docker-compose-pi.yml <<'EOF'
version: '3.8'

services:
  classdojo-app:
    build:
      context: .
      dockerfile: Dockerfile.arm
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
    deploy:
      resources:
        limits:
          memory: 256M
        reservations:
          memory: 128M
EOF

# Create .env file
echo "SECRET_KEY=${SECRET_KEY}" > ${APP_DIR}/.env
echo -e "${GREEN}✓ Configuration files created${NC}"
echo ""

echo -e "${BLUE}Step 6/6: Building and starting application...${NC}"
cd ${APP_DIR}
docker-compose -f docker-compose-pi.yml up -d --build

echo -e "${YELLOW}Waiting for application to be ready...${NC}"
sleep 15

# Check if container is running
if docker ps | grep -q classdojo-debit-system; then
    echo -e "${GREEN}✓ Application is running${NC}"
else
    echo -e "${RED}✗ Application failed to start${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    docker-compose -f ${APP_DIR}/docker-compose-pi.yml logs
    exit 1
fi
echo ""

# Get the Raspberry Pi's IP address
PI_IP=$(hostname -I | awk '{print $1}')

# Create management script
cat > /usr/local/bin/classdojo-manage << 'MANAGE_EOF'
#!/bin/bash

APP_DIR="/opt/classdojo"
COMPOSE_FILE="${APP_DIR}/docker-compose-pi.yml"

case "$1" in
    start)
        echo "Starting ClassDojo Debit System..."
        docker-compose -f ${COMPOSE_FILE} up -d
        ;;
    stop)
        echo "Stopping ClassDojo Debit System..."
        docker-compose -f ${COMPOSE_FILE} down
        ;;
    restart)
        echo "Restarting ClassDojo Debit System..."
        docker-compose -f ${COMPOSE_FILE} restart
        ;;
    logs)
        docker-compose -f ${COMPOSE_FILE} logs -f
        ;;
    status)
        docker-compose -f ${COMPOSE_FILE} ps
        ;;
    backup)
        BACKUP_FILE="${HOME}/classdojo-backup-$(date +%Y%m%d-%H%M%S).db"
        docker cp classdojo-debit-system:/app/database/school_debit.db "${BACKUP_FILE}"
        echo "Database backed up to: ${BACKUP_FILE}"
        ;;
    restore)
        if [ -z "$2" ]; then
            echo "Usage: classdojo-manage restore <backup-file>"
            exit 1
        fi
        docker cp "$2" classdojo-debit-system:/app/database/school_debit.db
        docker-compose -f ${COMPOSE_FILE} restart
        echo "Database restored from: $2"
        ;;
    update)
        echo "Updating ClassDojo Debit System..."
        cd ${APP_DIR}
        docker-compose -f ${COMPOSE_FILE} down
        docker-compose -f ${COMPOSE_FILE} build --no-cache
        docker-compose -f ${COMPOSE_FILE} up -d
        echo "Update complete!"
        ;;
    access)
        PI_IP=$(hostname -I | awk '{print $1}')
        echo "ClassDojo Debit System Access:"
        echo "  Local: http://localhost:5000"
        echo "  Network: http://${PI_IP}:5000"
        ;;
    *)
        echo "ClassDojo Debit System Management"
        echo ""
        echo "Usage: classdojo-manage [command]"
        echo ""
        echo "Commands:"
        echo "  start      - Start the application"
        echo "  stop       - Stop the application"
        echo "  restart    - Restart the application"
        echo "  logs       - View application logs"
        echo "  status     - Check application status"
        echo "  backup     - Backup the database"
        echo "  restore    - Restore database from backup"
        echo "  update     - Update and rebuild the application"
        echo "  access     - Show access URLs"
        ;;
esac
MANAGE_EOF

chmod +x /usr/local/bin/classdojo-manage

# Create systemd service for auto-start
cat > /etc/systemd/system/classdojo-docker.service <<'SERVICE_EOF'
[Unit]
Description=ClassDojo Debit System (Docker Compose)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/classdojo
ExecStart=/usr/local/bin/docker-compose -f /opt/classdojo/docker-compose-pi.yml up -d
ExecStop=/usr/local/bin/docker-compose -f /opt/classdojo/docker-compose-pi.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl daemon-reload
systemctl enable classdojo-docker.service

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Access Information:${NC}"
echo -e "  Local access: ${GREEN}http://localhost:5000${NC}"
echo -e "  Network access: ${GREEN}http://${PI_IP}:5000${NC}"
echo ""
echo -e "${YELLOW}Management Commands:${NC}"
echo -e "  Start app: ${BLUE}classdojo-manage start${NC}"
echo -e "  Stop app: ${BLUE}classdojo-manage stop${NC}"
echo -e "  Restart app: ${BLUE}classdojo-manage restart${NC}"
echo -e "  View logs: ${BLUE}classdojo-manage logs${NC}"
echo -e "  Check status: ${BLUE}classdojo-manage status${NC}"
echo -e "  Backup database: ${BLUE}classdojo-manage backup${NC}"
echo -e "  Show access info: ${BLUE}classdojo-manage access${NC}"
echo ""
echo -e "${YELLOW}Docker Compose Commands:${NC}"
echo -e "  View logs: ${BLUE}docker-compose -f ${APP_DIR}/docker-compose-pi.yml logs -f${NC}"
echo -e "  Restart: ${BLUE}docker-compose -f ${APP_DIR}/docker-compose-pi.yml restart${NC}"
echo -e "  Stop: ${BLUE}docker-compose -f ${APP_DIR}/docker-compose-pi.yml down${NC}"
echo -e "  Start: ${BLUE}docker-compose -f ${APP_DIR}/docker-compose-pi.yml up -d${NC}"
echo ""
echo -e "${YELLOW}Your generated secret key has been saved to:${NC}"
echo -e "  ${APP_DIR}/.env"
echo ""
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${YELLOW}The application will automatically start on boot.${NC}"
echo ""
