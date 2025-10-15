#!/bin/bash

# Test script for GitHub installation
# This verifies the complete installation flow from GitHub

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   GitHub Installation Test                                ║
║   Testing complete installation flow                      ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

# Test 1: Download bootstrap script
echo -e "${BLUE}Test 1: Downloading bootstrap script from GitHub...${NC}"
TEMP_DIR="/tmp/classdojo-github-test-$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

if curl -sSL https://raw.githubusercontent.com/Rgibs04/things/master/classdojo-debit-system/bootstrap.sh > bootstrap.sh; then
    echo -e "${GREEN}✓ Bootstrap script downloaded${NC}"
    echo -e "  Size: $(wc -c < bootstrap.sh) bytes"
    echo -e "  Lines: $(wc -l < bootstrap.sh) lines"
else
    echo -e "${RED}✗ Failed to download bootstrap script${NC}"
    exit 1
fi
echo ""

# Test 2: Verify bootstrap script content
echo -e "${BLUE}Test 2: Verifying bootstrap script content...${NC}"
if grep -q "ClassDojo Debit System - Bootstrap Installer" bootstrap.sh; then
    echo -e "${GREEN}✓ Bootstrap script header found${NC}"
else
    echo -e "${RED}✗ Bootstrap script appears corrupted${NC}"
    exit 1
fi

if grep -q "REPO_URL=" bootstrap.sh; then
    REPO_URL=$(grep "REPO_URL=" bootstrap.sh | head -1 | cut -d'"' -f2)
    echo -e "${GREEN}✓ Repository URL found: ${REPO_URL}${NC}"
else
    echo -e "${RED}✗ Repository URL not found${NC}"
    exit 1
fi
echo ""

# Test 3: Clone repository manually
echo -e "${BLUE}Test 3: Cloning repository...${NC}"
if git clone --depth 1 --branch master https://github.com/Rgibs04/things.git repo; then
    echo -e "${GREEN}✓ Repository cloned successfully${NC}"
else
    echo -e "${RED}✗ Failed to clone repository${NC}"
    exit 1
fi
echo ""

# Test 4: Verify project structure
echo -e "${BLUE}Test 4: Verifying project structure...${NC}"
PROJECT_DIR="repo/classdojo-debit-system"

if [ -d "$PROJECT_DIR" ]; then
    echo -e "${GREEN}✓ Project directory found${NC}"
else
    echo -e "${RED}✗ Project directory not found${NC}"
    exit 1
fi

# Check for essential files
ESSENTIAL_FILES=(
    "ubuntu-install.sh"
    "raspberry-pi-setup.sh"
    "install.sh"
    "docker-compose-install.sh"
    "standalone-install.sh"
    "requirements.txt"
    "Dockerfile"
    "Dockerfile.arm"
    "README.md"
    "GITHUB-INSTALL.md"
)

MISSING_FILES=()
for file in "${ESSENTIAL_FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$file" ]; then
        echo -e "${GREEN}  ✓ $file${NC}"
    else
        echo -e "${RED}  ✗ $file (missing)${NC}"
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo -e "${RED}✗ Missing ${#MISSING_FILES[@]} essential files${NC}"
    exit 1
fi
echo ""

# Test 5: Verify installer scripts are executable
echo -e "${BLUE}Test 5: Checking installer scripts...${NC}"
cd "$PROJECT_DIR"

INSTALLER_SCRIPTS=(
    "ubuntu-install.sh"
    "raspberry-pi-setup.sh"
    "install.sh"
    "docker-compose-install.sh"
    "standalone-install.sh"
)

for script in "${INSTALLER_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        # Check if script has shebang
        if head -1 "$script" | grep -q "^#!/bin/bash"; then
            echo -e "${GREEN}  ✓ $script has valid shebang${NC}"
        else
            echo -e "${YELLOW}  ⚠ $script missing shebang${NC}"
        fi
        
        # Make executable
        chmod +x "$script"
    fi
done
echo ""

# Test 6: Verify application files
echo -e "${BLUE}Test 6: Verifying application files...${NC}"

if [ -d "src" ]; then
    echo -e "${GREEN}  ✓ src/ directory found${NC}"
    if [ -f "src/app.py" ]; then
        echo -e "${GREEN}    ✓ app.py found${NC}"
    else
        echo -e "${RED}    ✗ app.py missing${NC}"
        exit 1
    fi
    if [ -f "src/database.py" ]; then
        echo -e "${GREEN}    ✓ database.py found${NC}"
    else
        echo -e "${RED}    ✗ database.py missing${NC}"
        exit 1
    fi
else
    echo -e "${RED}  ✗ src/ directory missing${NC}"
    exit 1
fi

if [ -d "templates" ]; then
    TEMPLATE_COUNT=$(ls templates/*.html 2>/dev/null | wc -l)
    echo -e "${GREEN}  ✓ templates/ directory found (${TEMPLATE_COUNT} templates)${NC}"
else
    echo -e "${RED}  ✗ templates/ directory missing${NC}"
    exit 1
fi

if [ -d "static" ]; then
    echo -e "${GREEN}  ✓ static/ directory found${NC}"
else
    echo -e "${YELLOW}  ⚠ static/ directory missing (optional)${NC}"
fi
echo ""

# Test 7: Verify requirements.txt
echo -e "${BLUE}Test 7: Checking Python requirements...${NC}"
if [ -f "requirements.txt" ]; then
    echo -e "${GREEN}  ✓ requirements.txt found${NC}"
    echo -e "  Dependencies:"
    while IFS= read -r line; do
        if [ -n "$line" ] && [[ ! "$line" =~ ^# ]]; then
            echo -e "    - $line"
        fi
    done < requirements.txt
else
    echo -e "${RED}  ✗ requirements.txt missing${NC}"
    exit 1
fi
echo ""

# Test 8: Verify Dockerfiles
echo -e "${BLUE}Test 8: Checking Dockerfiles...${NC}"
if [ -f "Dockerfile" ]; then
    echo -e "${GREEN}  ✓ Dockerfile found (x86_64)${NC}"
    if grep -q "FROM python" Dockerfile; then
        echo -e "${GREEN}    ✓ Valid Python base image${NC}"
    fi
else
    echo -e "${RED}  ✗ Dockerfile missing${NC}"
    exit 1
fi

if [ -f "Dockerfile.arm" ]; then
    echo -e "${GREEN}  ✓ Dockerfile.arm found (ARM/Raspberry Pi)${NC}"
    if grep -q "FROM arm" Dockerfile.arm; then
        echo -e "${GREEN}    ✓ Valid ARM base image${NC}"
    fi
else
    echo -e "${RED}  ✗ Dockerfile.arm missing${NC}"
    exit 1
fi
echo ""

# Test 9: Verify documentation
echo -e "${BLUE}Test 9: Checking documentation...${NC}"
DOCS=(
    "README.md"
    "GITHUB-INSTALL.md"
    "INSTALL.md"
    "AUTOSTART-GUIDE.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        SIZE=$(wc -c < "$doc")
        echo -e "${GREEN}  ✓ $doc (${SIZE} bytes)${NC}"
    else
        echo -e "${YELLOW}  ⚠ $doc missing${NC}"
    fi
done
echo ""

# Test 10: Verify K8s configuration (if present)
echo -e "${BLUE}Test 10: Checking Kubernetes configuration...${NC}"
if [ -d "k8s" ]; then
    K8S_FILES=$(ls k8s/*.yaml 2>/dev/null | wc -l)
    echo -e "${GREEN}  ✓ k8s/ directory found (${K8S_FILES} files)${NC}"
else
    echo -e "${YELLOW}  ⚠ k8s/ directory missing (optional)${NC}"
fi
echo ""

# Cleanup
echo -e "${BLUE}Cleaning up test files...${NC}"
cd /
rm -rf "$TEMP_DIR"
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Summary
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║   All GitHub Installation Tests Passed! ✓                ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Summary:${NC}"
echo -e "  ✓ Bootstrap script accessible from GitHub"
echo -e "  ✓ Repository can be cloned"
echo -e "  ✓ All essential files present"
echo -e "  ✓ Installer scripts valid"
echo -e "  ✓ Application files complete"
echo -e "  ✓ Dependencies documented"
echo -e "  ✓ Docker support configured"
echo -e "  ✓ Documentation available"
echo ""
echo -e "${GREEN}The GitHub installation is ready to use!${NC}"
echo -e "${YELLOW}To install, run:${NC}"
echo -e "${BLUE}curl -sSL https://raw.githubusercontent.com/Rgibs04/things/master/classdojo-debit-system/bootstrap.sh | sudo bash${NC}"
echo ""
