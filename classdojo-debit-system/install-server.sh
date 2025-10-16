#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_URL="https://github.com/Rgibs04/things.git"
REPO_SUBDIR="classdojo-debit-system"
INSTALL_DIR="/opt/classdojo"
TEMP_DIR="/tmp/classdojo-server-install"

clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ClassDojo Debit System - Server Installer               ║
║                                                           ║
║   Web Interface & Database for Central Server             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
    echo -e "Please run: ${YELLOW}curl -sSL [URL] | sudo bash${NC}"
    exit 1
fi

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

echo -e "${CYAN}Choose server installation method:${NC}"
echo -e "  ${GREEN}1)${NC} Docker Compose (Recommended - easy management)"
echo -e "  ${GREEN}2)${NC} Standalone Python (minimal resources)"
echo ""
read -p "Enter choice [1-2] (default: 1): " SERVER_METHOD
SERVER_METHOD=${SERVER_METHOD:-1}

echo ""
echo -e "${BLUE}Running pre-flight checks...${NC}"

if [ "$TOTAL_RAM" -lt 512 ]; then
    echo -e "${RED}✗ Insufficient RAM: ${TOTAL_RAM}MB (minimum 512MB required)${NC}"
    exit 1
fi
echo -e "${GREEN}✓ RAM check passed${NC}"

FREE_DISK=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$FREE_DISK" -lt 4 ]; then
    echo -e "${RED}✗ Insufficient disk space: ${FREE_DISK}GB free (minimum 4GB required)${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Disk space check passed${NC}"

if [[ ! "$ARCH" =~ ^(armv7l|aarch64|x86_64)$ ]]; then
    echo -e "${YELLOW}⚠ Warning: Architecture ${ARCH} may not be fully supported${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo -e "${GREEN}✓ Architecture check passed${NC}"

if ! ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${RED}✗ No internet connection detected${NC}"
    echo -e "${RED}  Please connect to the internet and try again${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Internet connectivity check passed${NC}"
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Installation Summary:${NC}"
echo -e "  Component: ${CYAN}Server (Web Interface & Database)${NC}"
echo -e "  Method: ${CYAN}$([ "$SERVER_METHOD" = "1" ] && echo "Docker Compose" || echo "Standalone Python")${NC}"
echo -e "  Directory: ${CYAN}${INSTALL_DIR}${NC}"
echo -e "  Estimated time: ${CYAN}10-15 minutes${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
#echo ""
#read -p "Proceed with server installation? (Y/n) " -n 1 -r
#echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Setting up installation environment...${NC}"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    apt-get update -qq
    apt-get install -y git
fi

echo -e "${BLUE}Downloading ClassDojo Debit System...${NC}"

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

# Install server
echo ""
echo -e "${BLUE}Installing Server Component...${NC}"

if [ "$SERVER_METHOD" = "1" ]; then
    # Docker Compose installation
    if [ -f "./docker-compose-install.sh" ]; then
        chmod +x ./docker-compose-install.sh
        bash ./docker-compose-install.sh
    else
        echo -e "${RED}Error: docker-compose-install.sh not found${NC}"
        exit 1
    fi
else
    # Standalone Python installation
    if [ -f "./standalone-install.sh" ]; then
        chmod +x ./standalone-install.sh
        bash ./standalone-install.sh
    else
        echo -e "${RED}Error: standalone-install.sh not found${NC}"
        exit 1
    fi
fi

# Cleanup
echo ""
echo -e "${BLUE}Cleaning up temporary files...${NC}"
cd /
rm -rf "$TEMP_DIR"

# Final message
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║   Server installation completed successfully! 🎉         ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Server Access:${NC}"
echo -e "  Web Admin: ${GREEN}http://localhost:5000${NC}"
echo -e "  Network: ${GREEN}http://[SERVER_IP]:5000${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo -e "  1. Access the web interface to set up admin account"
echo -e "  2. Import student data via CSV or email monitoring"
echo -e "  3. Configure kiosk clients to connect to this server"
echo -e "  4. Set up regular database backups"
echo ""
echo -e "${YELLOW}Management Commands:${NC}"
if [ "$SERVER_METHOD" = "1" ]; then
    echo -e "  Start: ${BLUE}classdojo-manage start${NC}"
    echo -e "  Stop: ${BLUE}classdojo-manage stop${NC}"
    echo -e "  Logs: ${BLUE}classdojo-manage logs${NC}"
    echo -e "  Backup: ${BLUE}classdojo-manage backup${NC}"
else
    echo -e "  Status: ${BLUE}sudo systemctl status classdojo${NC}"
    echo -e "  Logs: ${BLUE}sudo journalctl -u classdojo -f${NC}"
fi
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo -e "  Server Guide: ${INSTALL_DIR}/README-COMPREHENSIVE.md"
echo -e "  Installation: ${INSTALL_DIR}/INSTALL.md"
echo ""
echo -e "${GREEN}Server is ready for kiosk client connections!${NC}"
echo ""
