#!/bin/bash

# ClassDojo Debit System - Bootstrap Installer
# This script downloads the full project from GitHub and runs the installer
# Usage: curl -sSL https://raw.githubusercontent.com/Rgibs04/things/master/classdojo-debit-system/bootstrap.sh | sudo bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
REPO_URL="https://github.com/Rgibs04/things.git"
REPO_BRANCH="master"
PROJECT_DIR="classdojo-debit-system"
TEMP_DIR="/tmp/classdojo-install-$$"

# Banner
clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ClassDojo Debit System - Bootstrap Installer           ║
║                                                           ║
║   Downloading and installing from GitHub...              ║
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

# Detect OS
echo -e "${BLUE}Detecting system...${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$NAME
    OS_VERSION=$VERSION_ID
    echo -e "  OS: ${GREEN}${OS_NAME} ${OS_VERSION}${NC}"
else
    echo -e "${RED}Cannot detect OS. /etc/os-release not found.${NC}"
    exit 1
fi

# Check if Raspberry Pi
IS_RPI=false
if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    IS_RPI=true
    echo -e "  Device: ${GREEN}Raspberry Pi${NC}"
fi
echo ""

# Install git if not present
echo -e "${BLUE}Checking for git...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    apt-get update -qq
    apt-get install -y -qq git
    echo -e "${GREEN}✓ Git installed${NC}"
else
    echo -e "${GREEN}✓ Git already installed${NC}"
fi
echo ""

# Create temporary directory
echo -e "${BLUE}Creating temporary directory...${NC}"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
echo -e "${GREEN}✓ Temporary directory created: ${TEMP_DIR}${NC}"
echo ""

# Clone repository
echo -e "${BLUE}Downloading ClassDojo Debit System from GitHub...${NC}"
echo -e "${YELLOW}Repository: ${REPO_URL}${NC}"
echo -e "${YELLOW}Branch: ${REPO_BRANCH}${NC}"
echo ""

if git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" repo 2>&1 | grep -v "Cloning into"; then
    echo -e "${GREEN}✓ Repository downloaded successfully${NC}"
else
    echo -e "${RED}✗ Failed to download repository${NC}"
    echo -e "${RED}Please check your internet connection and try again${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo ""

# Navigate to project directory
if [ -d "repo/${PROJECT_DIR}" ]; then
    cd "repo/${PROJECT_DIR}"
    echo -e "${GREEN}✓ Found project directory${NC}"
else
    echo -e "${RED}✗ Project directory not found in repository${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo ""

# Determine which installer to use
INSTALLER=""
if [ "$IS_RPI" = true ]; then
    if [ -f "raspberry-pi-setup.sh" ]; then
        INSTALLER="raspberry-pi-setup.sh"
        echo -e "${GREEN}Using Raspberry Pi installer${NC}"
    fi
elif [[ "$OS_NAME" == *"Ubuntu"* ]] || [[ "$OS_NAME" == *"Debian"* ]]; then
    if [ -f "ubuntu-install.sh" ]; then
        INSTALLER="ubuntu-install.sh"
        echo -e "${GREEN}Using Ubuntu/Debian installer${NC}"
    fi
fi

# Fallback to generic installer
if [ -z "$INSTALLER" ] && [ -f "install.sh" ]; then
    INSTALLER="install.sh"
    echo -e "${GREEN}Using generic installer${NC}"
fi

if [ -z "$INSTALLER" ]; then
    echo -e "${RED}✗ No suitable installer found${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo ""

# Make installer executable
chmod +x "$INSTALLER"

# Run the installer
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Starting Installation                                   ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

bash "$INSTALLER"

# Cleanup
echo ""
echo -e "${BLUE}Cleaning up temporary files...${NC}"
cd /
rm -rf "$TEMP_DIR"
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║   Bootstrap installation completed! 🎉                   ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
