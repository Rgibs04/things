#!/bin/bash

# Test script for autostart functionality
# Tests Docker Compose method with systemd service

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ClassDojo Autostart Functionality Test                 ║${NC}"
echo -e "${BLUE}║   Testing Docker Compose Method                          ║${NC}"
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo ""

# Test 1: Check if Docker is installed
echo -e "${YELLOW}Test 1: Checking Docker installation...${NC}"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}✓ Docker is installed: ${DOCKER_VERSION}${NC}"
else
    echo -e "${RED}✗ Docker is not installed${NC}"
    exit 1
fi
echo ""

# Test 2: Check if Docker Compose is available
echo -e "${YELLOW}Test 2: Checking Docker Compose...${NC}"
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    echo -e "${GREEN}✓ Docker Compose is installed: ${COMPOSE_VERSION}${NC}"
elif docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    echo -e "${GREEN}✓ Docker Compose (plugin) is installed: ${COMPOSE_VERSION}${NC}"
else
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    exit 1
fi
echo ""

# Test 3: Check if application directory exists
echo -e "${YELLOW}Test 3: Checking application directory...${NC}"
if [ -d "/opt/classdojo" ]; then
    echo -e "${GREEN}✓ Application directory exists: /opt/classdojo${NC}"
    ls -la /opt/classdojo | head -10
else
    echo -e "${YELLOW}⚠ Application directory does not exist yet${NC}"
    echo -e "${YELLOW}  This is expected if installation hasn't run${NC}"
fi
echo ""

# Test 4: Check if systemd service file would be created correctly
echo -e "${YELLOW}Test 4: Checking systemd service configuration...${NC}"
if [ -f "/etc/systemd/system/classdojo-docker.service" ]; then
    echo -e "${GREEN}✓ Systemd service file exists${NC}"
    echo -e "${BLUE}Service file contents:${NC}"
    cat /etc/systemd/system/classdojo-docker.service
    echo ""
    
    # Test 5: Check if service is enabled
    echo -e "${YELLOW}Test 5: Checking if service is enabled...${NC}"
    if systemctl is-enabled classdojo-docker.service &> /dev/null; then
        echo -e "${GREEN}✓ Service is enabled for autostart${NC}"
    else
        echo -e "${RED}✗ Service is not enabled${NC}"
    fi
    echo ""
    
    # Test 6: Check service status
    echo -e "${YELLOW}Test 6: Checking service status...${NC}"
    systemctl status classdojo-docker.service --no-pager || true
    echo ""
    
else
    echo -e "${YELLOW}⚠ Systemd service file does not exist yet${NC}"
    echo -e "${YELLOW}  This is expected if Docker Compose installation hasn't run${NC}"
fi
echo ""

# Test 7: Check if Docker container exists
echo -e "${YELLOW}Test 7: Checking Docker container...${NC}"
if docker ps -a | grep -q classdojo-debit-system; then
    echo -e "${GREEN}✓ Docker container exists${NC}"
    docker ps -a | grep classdojo-debit-system
    echo ""
    
    # Test 8: Check container restart policy
    echo -e "${YELLOW}Test 8: Checking container restart policy...${NC}"
    RESTART_POLICY=$(docker inspect classdojo-debit-system --format='{{.HostConfig.RestartPolicy.Name}}' 2>/dev/null || echo "not-found")
    if [ "$RESTART_POLICY" = "unless-stopped" ]; then
        echo -e "${GREEN}✓ Container has correct restart policy: ${RESTART_POLICY}${NC}"
    else
        echo -e "${RED}✗ Container restart policy is: ${RESTART_POLICY} (expected: unless-stopped)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Docker container does not exist yet${NC}"
    echo -e "${YELLOW}  This is expected if installation hasn't run${NC}"
fi
echo ""

# Test 9: Check if docker-compose.yml exists and has correct restart policy
echo -e "${YELLOW}Test 9: Checking docker-compose.yml configuration...${NC}"
if [ -f "/opt/classdojo/docker-compose.yml" ]; then
    echo -e "${GREEN}✓ docker-compose.yml exists${NC}"
    if grep -q "restart: unless-stopped" /opt/classdojo/docker-compose.yml; then
        echo -e "${GREEN}✓ docker-compose.yml has correct restart policy${NC}"
    else
        echo -e "${RED}✗ docker-compose.yml missing restart policy${NC}"
    fi
else
    echo -e "${YELLOW}⚠ docker-compose.yml does not exist yet${NC}"
fi
echo ""

# Test 10: Check management script
echo -e "${YELLOW}Test 10: Checking management script...${NC}"
if [ -f "/usr/local/bin/classdojo-manage" ]; then
    echo -e "${GREEN}✓ Management script exists${NC}"
    if [ -x "/usr/local/bin/classdojo-manage" ]; then
        echo -e "${GREEN}✓ Management script is executable${NC}"
    else
        echo -e "${RED}✗ Management script is not executable${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Management script does not exist yet${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Test Summary                                            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "/etc/systemd/system/classdojo-docker.service" ] && \
   systemctl is-enabled classdojo-docker.service &> /dev/null && \
   docker ps | grep -q classdojo-debit-system; then
    echo -e "${GREEN}✅ All autostart components are properly configured!${NC}"
    echo -e "${GREEN}   The application will automatically start on system boot.${NC}"
    echo ""
    echo -e "${BLUE}To test autostart:${NC}"
    echo -e "  1. Reboot the system: ${YELLOW}sudo reboot${NC}"
    echo -e "  2. After reboot, check: ${YELLOW}docker ps | grep classdojo${NC}"
    echo -e "  3. Or check service: ${YELLOW}sudo systemctl status classdojo-docker.service${NC}"
else
    echo -e "${YELLOW}⚠ Autostart configuration incomplete${NC}"
    echo -e "${YELLOW}   This is expected if installation hasn't been run yet.${NC}"
    echo ""
    echo -e "${BLUE}To install with autostart:${NC}"
    echo -e "  ${YELLOW}sudo bash ubuntu-install.sh${NC}"
    echo -e "  Choose option 1 (Docker Compose)"
fi
echo ""
