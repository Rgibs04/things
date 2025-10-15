#!/bin/bash

# ClassDojo Debit System - Installation Test Script
# Verifies that the installation completed successfully

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}ClassDojo Installation Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2
    
    echo -n "Testing ${test_name}... "
    
    if eval "$test_command" &> /dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Detect installation method
INSTALL_METHOD="unknown"
if systemctl is-active --quiet classdojo 2>/dev/null; then
    INSTALL_METHOD="standalone"
elif docker ps | grep -q classdojo-debit-system 2>/dev/null; then
    INSTALL_METHOD="docker-compose"
elif command -v k3s &> /dev/null && sudo k3s kubectl get pods -n classdojo-system &> /dev/null; then
    INSTALL_METHOD="k3s"
fi

echo -e "${YELLOW}Detected installation method: ${INSTALL_METHOD}${NC}"
echo ""

# System Tests
echo -e "${BLUE}System Tests:${NC}"
run_test "Python 3 installed" "command -v python3"
run_test "Sufficient RAM (>512MB)" "[ $(free -m | awk '/^Mem:/{print $2}') -gt 512 ]"
run_test "Sufficient disk space (>2GB)" "[ $(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//') -gt 2 ]"
run_test "Internet connectivity" "ping -c 1 8.8.8.8"
echo ""

# Installation-specific tests
case $INSTALL_METHOD in
    standalone)
        echo -e "${BLUE}Standalone Installation Tests:${NC}"
        run_test "Application directory exists" "[ -d /opt/classdojo ]"
        run_test "Virtual environment exists" "[ -d /opt/classdojo/venv ]"
        run_test "Service is active" "systemctl is-active --quiet classdojo"
        run_test "Service is enabled" "systemctl is-enabled --quiet classdojo"
        run_test "Database exists" "[ -f /opt/classdojo/database/school_debit.db ]"
        run_test "Management script exists" "[ -f /usr/local/bin/classdojo-manage ]"
        ;;
        
    docker-compose)
        echo -e "${BLUE}Docker Compose Installation Tests:${NC}"
        run_test "Docker installed" "command -v docker"
        run_test "Docker Compose installed" "command -v docker-compose"
        run_test "Application directory exists" "[ -d /opt/classdojo ]"
        run_test "Docker Compose file exists" "[ -f /opt/classdojo/docker-compose-pi.yml ]"
        run_test "Container is running" "docker ps | grep -q classdojo-debit-system"
        run_test "Container is healthy" "docker inspect classdojo-debit-system | grep -q '\"Status\": \"healthy\"' || docker inspect classdojo-debit-system | grep -q '\"Status\": \"running\"'"
        run_test "Management script exists" "[ -f /usr/local/bin/classdojo-manage ]"
        ;;
        
    k3s)
        echo -e "${BLUE}K3s Installation Tests:${NC}"
        run_test "K3s installed" "command -v k3s"
        run_test "K3s is running" "systemctl is-active --quiet k3s"
        run_test "Namespace exists" "sudo k3s kubectl get namespace classdojo-system"
        run_test "Deployment exists" "sudo k3s kubectl get deployment -n classdojo-system classdojo-debit-system"
        run_test "Pod is running" "sudo k3s kubectl get pods -n classdojo-system -l app=classdojo-debit-system | grep -q Running"
        run_test "Service exists" "sudo k3s kubectl get svc -n classdojo-system classdojo-service"
        run_test "Access script exists" "[ -f /usr/local/bin/classdojo-access ]"
        ;;
        
    *)
        echo -e "${RED}No installation detected!${NC}"
        echo -e "${YELLOW}Please run one of the installation scripts first.${NC}"
        exit 1
        ;;
esac
echo ""

# Application Tests
echo -e "${BLUE}Application Tests:${NC}"

# Get the application URL
APP_URL="http://localhost:5000"

# Test if application is responding
if curl -s -o /dev/null -w "%{http_code}" "$APP_URL" | grep -q "200\|302"; then
    echo -e "Testing application response... ${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
else
    echo -e "Testing application response... ${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
fi

# Test health endpoint
if curl -s "$APP_URL/health" | grep -q "healthy\|running"; then
    echo -e "Testing health endpoint... ${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
else
    echo -e "Testing health endpoint... ${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
fi

# Test if port 5000 is listening
if netstat -tuln 2>/dev/null | grep -q ":5000" || ss -tuln 2>/dev/null | grep -q ":5000"; then
    echo -e "Testing port 5000 listening... ${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
else
    echo -e "Testing port 5000 listening... ${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
fi

echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Tests passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests failed: ${RED}${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo -e "${YELLOW}Access your application at:${NC}"
    PI_IP=$(hostname -I | awk '{print $1}')
    echo -e "  Local: ${GREEN}http://localhost:5000${NC}"
    echo -e "  Network: ${GREEN}http://${PI_IP}:5000${NC}"
    echo ""
    echo -e "${GREEN}Installation verified successfully! 🎉${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting steps:${NC}"
    
    case $INSTALL_METHOD in
        standalone)
            echo -e "  1. Check service status: ${BLUE}sudo systemctl status classdojo${NC}"
            echo -e "  2. View logs: ${BLUE}sudo journalctl -u classdojo -n 50${NC}"
            echo -e "  3. Restart service: ${BLUE}sudo systemctl restart classdojo${NC}"
            ;;
        docker-compose)
            echo -e "  1. Check container status: ${BLUE}docker ps -a${NC}"
            echo -e "  2. View logs: ${BLUE}docker-compose -f /opt/classdojo/docker-compose-pi.yml logs${NC}"
            echo -e "  3. Restart container: ${BLUE}docker-compose -f /opt/classdojo/docker-compose-pi.yml restart${NC}"
            ;;
        k3s)
            echo -e "  1. Check pod status: ${BLUE}sudo k3s kubectl get pods -n classdojo-system${NC}"
            echo -e "  2. View logs: ${BLUE}sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system${NC}"
            echo -e "  3. Describe pod: ${BLUE}sudo k3s kubectl describe pod -n classdojo-system -l app=classdojo-debit-system${NC}"
            ;;
    esac
    
    echo ""
    echo -e "${YELLOW}For more help, see: ${BLUE}INSTALL.md${NC}"
    exit 1
fi
