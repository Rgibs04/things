#!/bin/bash

# ClassDojo Debit System - One-Liner Installer for Raspberry Pi 3B
# Usage: curl -sSL https://raw.githubusercontent.com/Rgibs04/things/master/classdojo-debit-system/install.sh | sudo bash
# Or: wget -qO- https://raw.githubusercontent.com/Rgibs04/things/master/classdojo-debit-system/install.sh | sudo bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/Rgibs04/things.git"
REPO_SUBDIR="classdojo-debit-system"
INSTALL_DIR="/opt/classdojo"
TEMP_DIR="/tmp/classdojo-install"

# Banner
clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ClassDojo Debit System - Raspberry Pi 3B Installer     ║
║                                                           ║
║   Automated Setup for Debian/Raspberry Pi OS             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
    echo -e "Please run: ${YELLOW}curl -sSL [URL] | sudo bash${NC}"
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
echo ""

# Check if Raspberry Pi
IS_RPI=false
if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    IS_RPI=true
    RPI_MODEL=$(grep "Model" /proc/cpuinfo | cut -d':' -f2 | xargs)
    echo -e "${GREEN}✓ Raspberry Pi detected: ${RPI_MODEL}${NC}"
else
    echo -e "${YELLOW}⚠ Not running on Raspberry Pi hardware${NC}"
    echo -e "${YELLOW}  Continuing anyway, but some optimizations may not apply${NC}"
fi
echo ""

# Pre-flight checks
echo -e "${BLUE}Running pre-flight checks...${NC}"

# Check RAM (minimum 512MB)
if [ "$TOTAL_RAM" -lt 512 ]; then
    echo -e "${RED}✗ Insufficient RAM: ${TOTAL_RAM}MB (minimum 512MB required)${NC}"
    exit 1
fi
echo -e "${GREEN}✓ RAM check passed${NC}"

# Check disk space (minimum 4GB free)
FREE_DISK=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$FREE_DISK" -lt 4 ]; then
    echo -e "${RED}✗ Insufficient disk space: ${FREE_DISK}GB free (minimum 4GB required)${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Disk space check passed${NC}"

# Check architecture (ARM)
if [[ ! "$ARCH" =~ ^(armv7l|aarch64|x86_64)$ ]]; then
    echo -e "${YELLOW}⚠ Warning: Architecture ${ARCH} may not be fully supported${NC}"
    echo -e "${YELLOW}  This installer is optimized for ARM (Raspberry Pi)${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo -e "${GREEN}✓ Architecture check passed${NC}"

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
echo -e "  ${GREEN}1)${NC} Full installation with K3s (Kubernetes) - Recommended for production"
echo -e "  ${GREEN}2)${NC} Lightweight installation with Docker Compose - Simpler, lower resources"
echo -e "  ${GREEN}3)${NC} Standalone Python installation - No containers, direct install"
echo ""
read -p "Enter choice [1-3] (default: 2): " INSTALL_METHOD
INSTALL_METHOD=${INSTALL_METHOD:-2}

# Confirm installation
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Installation Summary:${NC}"
echo -e "  Installation directory: ${CYAN}${INSTALL_DIR}${NC}"
echo -e "  Method: ${CYAN}$([ "$INSTALL_METHOD" = "1" ] && echo "K3s (Kubernetes)" || ([ "$INSTALL_METHOD" = "2" ] && echo "Docker Compose" || echo "Standalone Python"))${NC}"
echo -e "  Estimated time: ${CYAN}15-30 minutes${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
read -p "Proceed with installation? (Y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    exit 0
fi

# Create temporary directory
echo ""
echo -e "${BLUE}Setting up installation environment...${NC}"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    apt-get update -qq
    apt-get install -y git
fi

# Download the project
echo -e "${BLUE}Downloading ClassDojo Debit System...${NC}"

# Clone the repository
if [ -n "$REPO_URL" ]; then
    git clone "$REPO_URL" "$TEMP_DIR/things"
    if [ -d "$TEMP_DIR/things/$REPO_SUBDIR" ]; then
        cd "$TEMP_DIR/things/$REPO_SUBDIR"
        echo -e "${GREEN}✓ Repository downloaded${NC}"
    else
        echo -e "${RED}Error: Could not find $REPO_SUBDIR in repository${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: Repository URL not configured${NC}"
    exit 1
fi

# Run the appropriate installation method
case $INSTALL_METHOD in
    1)
        echo -e "${BLUE}Starting K3s installation...${NC}"
        if [ -f "./raspberry-pi-setup.sh" ]; then
            chmod +x ./raspberry-pi-setup.sh
            bash ./raspberry-pi-setup.sh
        else
            echo -e "${RED}Error: raspberry-pi-setup.sh not found${NC}"
            exit 1
        fi
        ;;
    2)
        echo -e "${BLUE}Starting Docker Compose installation...${NC}"
        if [ -f "./docker-compose-install.sh" ]; then
            chmod +x ./docker-compose-install.sh
            bash ./docker-compose-install.sh
        else
            # Create inline Docker Compose installer
            bash -c "$(cat <<'INSTALLER_EOF'
#!/bin/bash
set -e

echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker pi 2>/dev/null || true
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
fi

echo "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    apt-get install -y python3-pip
    pip3 install docker-compose
fi

echo "Setting up application..."
mkdir -p /opt/classdojo
cp -r ./* /opt/classdojo/
cd /opt/classdojo

# Generate secret key
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")

# Create Docker Compose file if it doesn't exist
if [ ! -f "docker-compose-pi.yml" ]; then
    cat > docker-compose-pi.yml <<'EOF'
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
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:5000/health').read()"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
EOF
fi

# Create .env file
echo "SECRET_KEY=${SECRET_KEY}" > .env

echo "Building and starting application..."
docker-compose -f docker-compose-pi.yml up -d --build

echo "Waiting for application to be ready..."
sleep 10

# Get IP address
PI_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Access your application at:"
echo "  Local: http://localhost:5000"
echo "  Network: http://${PI_IP}:5000"
echo ""
echo "Useful commands:"
echo "  View logs: docker-compose -f /opt/classdojo/docker-compose-pi.yml logs -f"
echo "  Restart: docker-compose -f /opt/classdojo/docker-compose-pi.yml restart"
echo "  Stop: docker-compose -f /opt/classdojo/docker-compose-pi.yml down"
echo "  Start: docker-compose -f /opt/classdojo/docker-compose-pi.yml up -d"
echo ""
INSTALLER_EOF
)"
        fi
        ;;
    3)
        echo -e "${BLUE}Starting standalone Python installation...${NC}"
        bash -c "$(cat <<'INSTALLER_EOF'
#!/bin/bash
set -e

echo "Installing Python dependencies..."
apt-get update
apt-get install -y python3 python3-pip python3-venv sqlite3

echo "Setting up application..."
mkdir -p /opt/classdojo
cp -r ./* /opt/classdojo/
cd /opt/classdojo

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install requirements
pip install -r requirements.txt

# Generate secret key
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")

# Create systemd service
cat > /etc/systemd/system/classdojo.service <<EOF
[Unit]
Description=ClassDojo Debit System
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/classdojo
Environment="SECRET_KEY=${SECRET_KEY}"
Environment="FLASK_ENV=production"
ExecStart=/opt/classdojo/venv/bin/python src/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable classdojo
systemctl start classdojo

# Get IP address
PI_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Access your application at:"
echo "  Local: http://localhost:5000"
echo "  Network: http://${PI_IP}:5000"
echo ""
echo "Useful commands:"
echo "  View logs: journalctl -u classdojo -f"
echo "  Restart: systemctl restart classdojo"
echo "  Stop: systemctl stop classdojo"
echo "  Start: systemctl start classdojo"
echo "  Status: systemctl status classdojo"
echo ""
INSTALLER_EOF
)"
        ;;
esac

# Cleanup
echo ""
echo -e "${BLUE}Cleaning up temporary files...${NC}"
cd /
rm -rf "$TEMP_DIR"

# Final message
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║   Installation completed successfully! 🎉                ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo -e "  1. Access the web interface at the URL shown above"
echo -e "  2. Import student data or add students manually"
echo -e "  3. Assign cards to students"
echo -e "  4. Start processing transactions!"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo -e "  Installation guide: ${INSTALL_DIR}/INSTALL.md"
echo -e "  User guide: ${INSTALL_DIR}/README.md"
echo -e "  Raspberry Pi guide: ${INSTALL_DIR}/RASPBERRY-PI-GUIDE.md"
echo ""
echo -e "${GREEN}Thank you for using ClassDojo Debit System!${NC}"
echo ""
