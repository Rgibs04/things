#!/bin/bash

# Test script for Ubuntu installation
# This will test the standalone Python installation (fastest method)

echo "Starting Ubuntu 24.04 installation test..."
echo ""

# Navigate to the project directory
cd /mnt/c/Users/harle/Documents/classdojo-debit-system/classdojo-debit-system

# Run the installer with automatic responses
# Option 2 = Standalone Python
# Y = Proceed with installation
echo -e "2\nY" | sudo bash ubuntu-install.sh

# Check if installation was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "Installation test completed successfully!"
    echo ""
    echo "Testing application..."
    
    # Wait a moment for the service to fully start
    sleep 5
    
    # Test if the application is responding
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        echo "✓ Application is responding on port 5000"
        echo ""
        echo "Testing health endpoint..."
        curl -s http://localhost:5000/health | python3 -m json.tool
    else
        echo "✗ Application is not responding"
        echo "Checking service status..."
        sudo systemctl status classdojo
        echo ""
        echo "Checking logs..."
        sudo journalctl -u classdojo -n 50 --no-pager
    fi
else
    echo ""
    echo "Installation test failed!"
    exit 1
fi
