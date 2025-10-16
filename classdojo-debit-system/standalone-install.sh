#!/bin/bash

# ClassDojo Debit System - Standalone Python Installation Script
# Minimal installation without containers for Raspberry Pi 3B

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ClassDojo Debit System${NC}"
echo -e "${GREEN}Standalone Python Installation${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
    exit 1
fi

# Configuration
APP_DIR="/opt/classdojo"
SERVICE_USER="pos-server"

echo -e "${BLUE}Step 1/7: Updating system packages...${NC}"
apt-get update
apt-get upgrade -y
echo -e "${GREEN}✓ System updated${NC}"
echo ""

echo -e "${BLUE}Step 2/7: Installing Python and dependencies...${NC}"
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    sqlite3 \
    git
echo -e "${GREEN}✓ Python and dependencies installed${NC}"
echo ""

echo -e "${BLUE}Step 3/7: Setting up application directory...${NC}"
mkdir -p ${APP_DIR}
mkdir -p ${APP_DIR}/database

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
echo -e "${GREEN}✓ Application directory set up${NC}"
echo ""

echo -e "${BLUE}Step 4/7: Creating Python virtual environment...${NC}"
python3 -m venv ${APP_DIR}/venv
source ${APP_DIR}/venv/bin/activate

echo -e "${YELLOW}Installing Python packages...${NC}"
pip install --upgrade pip
pip install -r ${APP_DIR}/requirements.txt

deactivate
echo -e "${GREEN}✓ Virtual environment created and packages installed${NC}"
echo ""

echo -e "${BLUE}Step 5/7: Generating secure secret key...${NC}"
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
echo -e "${GREEN}✓ Secret key generated${NC}"
echo ""

echo -e "${BLUE}Step 6/7: Creating systemd service...${NC}"

# Create environment file
cat > ${APP_DIR}/.env <<EOF
SECRET_KEY=${SECRET_KEY}
FLASK_ENV=production
EOF

# Create systemd service file
cat > /etc/systemd/system/classdojo.service <<EOF
[Unit]
Description=ClassDojo Debit System
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
WorkingDirectory=${APP_DIR}
Environment="PATH=${APP_DIR}/venv/bin"
EnvironmentFile=${APP_DIR}/.env
ExecStart=${APP_DIR}/venv/bin/python ${APP_DIR}/src/app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${APP_DIR}/database

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chown -R ${SERVICE_USER}:${SERVICE_USER} ${APP_DIR}
chmod 600 ${APP_DIR}/.env

echo -e "${GREEN}✓ Systemd service created${NC}"
echo ""

echo -e "${BLUE}Step 7/7: Starting application...${NC}"
systemctl daemon-reload
systemctl enable classdojo.service
systemctl start classdojo.service

# Wait for service to start
sleep 5

# Check if service is running
if systemctl is-active --quiet classdojo.service; then
    echo -e "${GREEN}✓ Application started successfully${NC}"
else
    echo -e "${RED}✗ Application failed to start${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    journalctl -u classdojo -n 20
    exit 1
fi
echo ""

# Get the Raspberry Pi's IP address
PI_IP=$(hostname -I | awk '{print $1}')

# Create management script
cat > /usr/local/bin/classdojo-manage << 'MANAGE_EOF'
#!/bin/bash

case "$1" in
    start)
        echo "Starting ClassDojo Debit System..."
        sudo systemctl start classdojo
        ;;
    stop)
        echo "Stopping ClassDojo Debit System..."
        sudo systemctl stop classdojo
        ;;
    restart)
        echo "Restarting ClassDojo Debit System..."
        sudo systemctl restart classdojo
        ;;
    status)
        sudo systemctl status classdojo
        ;;
    logs)
        sudo journalctl -u classdojo -f
        ;;
    enable)
        echo "Enabling ClassDojo to start on boot..."
        sudo systemctl enable classdojo
        ;;
    disable)
        echo "Disabling ClassDojo from starting on boot..."
        sudo systemctl disable classdojo
        ;;
    backup)
        BACKUP_FILE="${HOME}/classdojo-backup-$(date +%Y%m%d-%H%M%S).db"
        cp /opt/classdojo/database/school_debit.db "${BACKUP_FILE}"
        echo "Database backed up to: ${BACKUP_FILE}"
        ;;
    restore)
        if [ -z "$2" ]; then
            echo "Usage: classdojo-manage restore <backup-file>"
            exit 1
        fi
        sudo systemctl stop classdojo
        cp "$2" /opt/classdojo/database/school_debit.db
        sudo chown pi:pi /opt/classdojo/database/school_debit.db
        sudo systemctl start classdojo
        echo "Database restored from: $2"
        ;;
    update)
        echo "Updating ClassDojo Debit System..."
        cd /opt/classdojo
        sudo systemctl stop classdojo
        git pull 2>/dev/null || echo "Not a git repository, skipping git pull"
        source venv/bin/activate
        pip install --upgrade -r requirements.txt
        deactivate
        sudo systemctl start classdojo
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
        echo "  status     - Check application status"
        echo "  logs       - View application logs (live)"
        echo "  enable     - Enable auto-start on boot"
        echo "  disable    - Disable auto-start on boot"
        echo "  backup     - Backup the database"
        echo "  restore    - Restore database from backup"
        echo "  update     - Update the application"
        echo "  access     - Show access URLs"
        ;;
esac
MANAGE_EOF

chmod +x /usr/local/bin/classdojo-manage

# Create log rotation configuration
cat > /etc/logrotate.d/classdojo <<EOF
/var/log/classdojo/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 ${SERVICE_USER} ${SERVICE_USER}
    sharedscripts
    postrotate
        systemctl reload classdojo > /dev/null 2>&1 || true
    endscript
}
EOF

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
echo -e "  View status: ${BLUE}classdojo-manage status${NC}"
echo -e "  View logs: ${BLUE}classdojo-manage logs${NC}"
echo -e "  Backup database: ${BLUE}classdojo-manage backup${NC}"
echo -e "  Show access info: ${BLUE}classdojo-manage access${NC}"
echo ""
echo -e "${YELLOW}Systemd Commands:${NC}"
echo -e "  View status: ${BLUE}sudo systemctl status classdojo${NC}"
echo -e "  View logs: ${BLUE}sudo journalctl -u classdojo -f${NC}"
echo -e "  Restart: ${BLUE}sudo systemctl restart classdojo${NC}"
echo -e "  Stop: ${BLUE}sudo systemctl stop classdojo${NC}"
echo -e "  Start: ${BLUE}sudo systemctl start classdojo${NC}"
echo ""
echo -e "${YELLOW}Your generated secret key has been saved to:${NC}"
echo -e "  ${APP_DIR}/.env"
echo ""
echo -e "${YELLOW}Application files location:${NC}"
echo -e "  ${APP_DIR}"
echo ""
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${YELLOW}The application will automatically start on boot.${NC}"
echo ""
echo -e "${CYAN}Resource Usage:${NC}"
echo -e "  RAM: ~100MB"
echo -e "  Disk: ~500MB"
echo -e "  CPU: Minimal when idle"
echo ""
