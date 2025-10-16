#!/bin/bash

# ClassDojo Debit System - Kiosk Client Installer
# Installs the kiosk application on client machines

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ClassDojo Debit System - Kiosk Installer${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root (may be needed for some operations)
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}Warning: Running as root. Some operations may require root access.${NC}"
    echo ""
fi

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    PACKAGE_MANAGER="apt-get"
    if command -v apt &> /dev/null; then
        PACKAGE_MANAGER="apt"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    PACKAGE_MANAGER="brew"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
    PACKAGE_MANAGER="choco"
else
    echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
    exit 1
fi

echo -e "${BLUE}Detected OS: ${GREEN}${OS}${NC}"
echo ""

# Check Python version
echo -e "${BLUE}Checking Python version...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python 3 not found. Please install Python 3.7 or higher.${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
REQUIRED_VERSION="3.7"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo -e "${RED}Python $PYTHON_VERSION found, but Python $REQUIRED_VERSION or higher is required.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Python $PYTHON_VERSION found${NC}"
echo ""

# Install system dependencies
echo -e "${BLUE}Installing system dependencies...${NC}"

case $OS in
    linux)
        if command -v apt &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y python3-pip python3-pyqt5 python3-serial
        elif command -v yum &> /dev/null; then
            sudo yum install -y python3-pip python3-qt5 python3-pyserial
        elif command -v pacman &> /dev/null; then
            sudo pacman -S python-pip python-pyqt5 python-pyserial
        fi

        # Add user to dialout group for serial access
        if groups $USER | grep -q dialout; then
            echo -e "${GREEN}✓ User already in dialout group${NC}"
        else
            sudo usermod -a -G dialout $USER
            echo -e "${YELLOW}Added user to dialout group. Please log out and back in for changes to take effect.${NC}"
        fi
        ;;
    macos)
        if ! command -v brew &> /dev/null; then
            echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install python3 qt5 pyserial
        ;;
    windows)
        echo -e "${YELLOW}Please ensure the following are installed on Windows:${NC}"
        echo -e "  - Python 3.7+ (https://python.org)"
        echo -e "  - PyQt5 (pip install PyQt5)"
        echo -e "  - pywin32 (pip install pywin32)"
        echo -e "  - pyserial (pip install pyserial)"
        ;;
esac

echo -e "${GREEN}✓ System dependencies installed${NC}"
echo ""

# Install Python dependencies
echo -e "${BLUE}Installing Python dependencies...${NC}"
pip3 install -r requirements.txt
echo -e "${GREEN}✓ Python dependencies installed${NC}"
echo ""

# Create desktop shortcut (Linux)
if [[ "$OS" == "linux" ]]; then
    echo -e "${BLUE}Creating desktop shortcut...${NC}"

    DESKTOP_FILE="$HOME/Desktop/classdojo-kiosk.desktop"
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ClassDojo Debit Kiosk
Comment=ClassDojo Debit Card System Kiosk
Exec=python3 $(pwd)/kiosk_app.py
Icon=$(pwd)/icon.png
Path=$(pwd)
Terminal=false
StartupWMClass=kiosk-app
EOF

    chmod +x "$DESKTOP_FILE"
    echo -e "${GREEN}✓ Desktop shortcut created${NC}"
fi

# Create startup script
echo -e "${BLUE}Creating startup script...${NC}"

STARTUP_SCRIPT="start-kiosk.sh"
cat > "$STARTUP_SCRIPT" << 'EOF'
#!/bin/bash
# ClassDojo Kiosk Startup Script

cd "$(dirname "$0")"

# Kill any existing kiosk processes
pkill -f kiosk_app.py || true

# Wait a moment
sleep 2

# Start kiosk
exec python3 kiosk_app.py "$@"
EOF

chmod +x "$STARTUP_SCRIPT"
echo -e "${GREEN}✓ Startup script created${NC}"
echo ""

# Create configuration template
echo -e "${BLUE}Creating configuration template...${NC}"

if [ ! -f "kiosk_config.json" ]; then
    cat > "kiosk_config_template.json" << 'EOF'
{
    "server_url": "http://localhost:5000",
    "kiosk_id": "auto-generated",
    "kiosk_name": "Kiosk Terminal",
    "admin_code": "ADMIN123",
    "timeout_seconds": 1800,
    "lock_timeout_seconds": 1800,
    "rfid_port": "/dev/ttyUSB0",
    "rfid_baudrate": 9600,
    "fullscreen": true,
    "auto_update": true,
    "github_repo": "yourusername/classdojo-debit-system",
    "update_interval_hours": 24
}
EOF
    echo -e "${GREEN}✓ Configuration template created${NC}"
else
    echo -e "${GREEN}✓ Configuration file already exists${NC}"
fi
echo ""

# Test installation
echo -e "${BLUE}Testing installation...${NC}"

# Test imports
python3 -c "
try:
    import sys
    sys.path.insert(0, '.')
    from kiosk_config import KioskConfig
    from rfid_reader import RFIDReader
    print('✓ All imports successful')
except ImportError as e:
    print(f'✗ Import error: {e}')
    sys.exit(1)
"

echo -e "${GREEN}✓ Installation test passed${NC}"
echo ""

# Final instructions
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo -e "1. ${GREEN}Configure the kiosk:${NC}"
echo -e "   - Edit kiosk_config.json (created from template)"
echo -e "   - Set correct server URL"
echo -e "   - Configure RFID reader port"
echo ""
echo -e "2. ${GREEN}Test the kiosk:${NC}"
echo -e "   ./start-kiosk.sh --dev    # Windowed mode"
echo -e "   ./start-kiosk.sh --mock-rfid  # With mock RFID reader"
echo ""
echo -e "3. ${GREEN}For production use:${NC}"
echo -e "   ./start-kiosk.sh           # Fullscreen kiosk mode"
echo ""

if [[ "$OS" == "linux" ]]; then
    echo -e "4. ${GREEN}Auto-start on boot (optional):${NC}"
    echo -e "   - Add $(pwd)/start-kiosk.sh to your startup applications"
    echo -e "   - Or create a systemd service"
    echo ""
fi

echo -e "${YELLOW}RFID Reader Setup:${NC}"
echo -e "  - Connect RFID reader to USB port"
echo -e "  - Check device path: ls /dev/ttyUSB*"
echo -e "  - Update rfid_port in kiosk_config.json"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo -e "  - Check client/README.md for detailed help"
echo -e "  - Test with mock RFID reader first"
echo -e "  - Verify server connectivity"
echo ""
echo -e "${GREEN}Happy scanning! 🎉${NC}"
echo ""

# Ask to start kiosk now
read -p "Would you like to start the kiosk now for testing? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Starting kiosk in development mode...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    sleep 2
    ./start-kiosk.sh --dev --mock-rfid
fi
