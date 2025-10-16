#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/Rgibs04/things.git"
REPO_SUBDIR="classdojo-debit-system"
CLIENT_DIR="/opt/classdojo-client"
TEMP_DIR="/tmp/classdojo-client-install"

clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ClassDojo Debit System - Client Installer              ║
║                                                           ║
║   Kiosk Application for POS Terminals                    ║
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
    echo -e "${YELLOW}  Continuing anyway, but touchscreen may not work${NC}"
fi
echo ""

echo -e "${CYAN}Server Configuration:${NC}"
echo -e "The kiosk client needs to connect to a ClassDojo Debit System server."
echo ""
read -p "Enter server IP address or hostname (default: auto-discover): " SERVER_IP
SERVER_IP=${SERVER_IP:-"auto"}

if [ "$SERVER_IP" = "auto" ]; then
    echo -e "${YELLOW}Client will auto-discover server on local network${NC}"
else
    echo -e "${GREEN}Client will connect to server: ${SERVER_IP}${NC}"
fi
echo ""

echo -e "${BLUE}Running pre-flight checks...${NC}"

if [ "$TOTAL_RAM" -lt 256 ]; then
    echo -e "${RED}✗ Insufficient RAM: ${TOTAL_RAM}MB (minimum 256MB required)${NC}"
    exit 1
fi
echo -e "${GREEN}✓ RAM check passed${NC}"

FREE_DISK=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$FREE_DISK" -lt 2 ]; then
    echo -e "${RED}✗ Insufficient disk space: ${FREE_DISK}GB free (minimum 2GB required)${NC}"
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
    echo -e "${RED}  Client needs internet to connect to server${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Internet connectivity check passed${NC}"
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Installation Summary:${NC}"
echo -e "  Component: ${CYAN}Client (Kiosk Application)${NC}"
echo -e "  Server: ${CYAN}$([ "$SERVER_IP" = "auto" ] && echo "Auto-discover" || echo "$SERVER_IP")${NC}"
echo -e "  Directory: ${CYAN}${CLIENT_DIR}${NC}"
echo -e "  Estimated time: ${CYAN}5-10 minutes${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
read -p "Proceed with client installation? (Y/n) " -n 1 -r
echo
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

# Install client
echo ""
echo -e "${BLUE}Installing Client Component...${NC}"

if [ -d "./client" ]; then
    mkdir -p ${CLIENT_DIR}
    cp -r ./client/* ${CLIENT_DIR}/
    cd ${CLIENT_DIR}

    if [ -f "./install.sh" ]; then
        chmod +x ./install.sh
        bash ./install.sh
    else
        echo -e "${RED}Error: client/install.sh not found${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: client directory not found${NC}"
    exit 1
fi

# Configure server connection
echo ""
echo -e "${BLUE}Configuring server connection...${NC}"

if [ -f "kiosk_config.json" ]; then
    # Update existing config
    if [ "$SERVER_IP" != "auto" ]; then
        # Use jq if available, otherwise sed
        if command -v jq &> /dev/null; then
            jq --arg server "http://$SERVER_IP:5000" '.server_url = $server' kiosk_config.json > temp.json && mv temp.json kiosk_config.json
        else
            # Fallback to sed (basic replacement)
            sed -i "s|\"server_url\": \"[^\"]*\"|\"server_url\": \"http://$SERVER_IP:5000\"|g" kiosk_config.json
        fi
        echo -e "${GREEN}✓ Server URL configured: http://$SERVER_IP:5000${NC}"
    else
        echo -e "${GREEN}✓ Auto-discovery enabled (client will find server automatically)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Config file not found - will be created on first run${NC}"
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
echo -e "${GREEN}║   Client installation completed successfully! 🎉         ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Client Configuration:${NC}"
if [ "$SERVER_IP" != "auto" ]; then
    echo -e "  Server: ${GREEN}http://$SERVER_IP:5000${NC}"
else
    echo -e "  Server: ${GREEN}Auto-discovering on local network${NC}"
fi
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo -e "  1. Connect RFID reader to USB port"
echo -e "  2. Test kiosk: cd ${CLIENT_DIR} && ./start-kiosk.sh --dev"
echo -e "  3. For production: ./start-kiosk.sh (fullscreen mode)"
echo -e "  4. Configure auto-startup if needed"
echo ""
echo -e "${YELLOW}RFID Reader Setup:${NC}"
echo -e "  - Check device: ls /dev/ttyUSB*"
echo -e "  - Update rfid_port in kiosk_config.json if needed"
echo -e "  - Test with: ./start-kiosk.sh --mock-rfid"
echo ""
echo -e "${YELLOW}Management Commands:${NC}"
echo -e "  Start kiosk: ${BLUE}cd ${CLIENT_DIR} && ./start-kiosk.sh${NC}"
echo -e "  Stop kiosk: ${BLUE}Ctrl+C or pkill -f kiosk_app.py${NC}"
echo -e "  View logs: ${BLUE}tail -f ${CLIENT_DIR}/kiosk.log${NC}"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo -e "  Client Guide: ${CLIENT_DIR}/README.md"
echo ""
echo -e "${GREEN}Client is ready to connect to server!${NC}"
echo ""
