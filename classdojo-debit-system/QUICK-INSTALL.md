# 🚀 Quick Install - ClassDojo Debit System

## Separate Server & Client Installation

### Step 1: Install Server (Central Database)
On your server machine (Raspberry Pi 3B+ or Ubuntu server):
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/classdojo-debit-system/main/install-server.sh | sudo bash
```

### Step 2: Install Clients (POS Terminals)
On each kiosk/touchscreen device:
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/classdojo-debit-system/main/install-client.sh | sudo bash
```

### Alternative: Universal Installer (Both on Same Machine)
For testing or single-machine setup:
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/classdojo-debit-system/main/install.sh | sudo bash
```

---

## What Gets Installed Where?

### Server Machine
- ✅ Web admin interface (http://server:5000)
- ✅ SQLite database with student data
- ✅ REST API for client connections
- ✅ Email monitoring for CSV imports
- ✅ Transaction processing and reporting

### Client Machines (Kiosks)
- ✅ Touchscreen kiosk application
- ✅ RFID card reader support
- ✅ Real-time connection to server
- ✅ Transaction processing interface
- ✅ Auto-locking security features

---

## After Installation

### Server Access
```
http://[SERVER_IP]:5000
```

### Client Configuration
Clients automatically discover the server on your local network, or you can manually configure the server IP during installation.

### Quick Management

**Server (Docker Compose):**
```bash
classdojo-manage start/stop/logs/backup/access
```

**Client (Kiosk):**
```bash
cd /opt/classdojo-client
./start-kiosk.sh          # Production mode
./start-kiosk.sh --dev    # Development mode
```

---

## System Requirements

### Server Machine
- Raspberry Pi 3B+ or Ubuntu/Debian server
- 512MB+ RAM, 4GB+ disk
- Static IP recommended
- Internet connection

### Client Machines (Kiosks)
- Raspberry Pi 3B+ with touchscreen
- 256MB+ RAM, 2GB+ disk
- USB RFID reader (optional)
- Network connection to server

---

## Network Setup

1. **Server**: Set static IP (192.168.1.100)
2. **Clients**: Connect to same network
3. **Firewall**: Allow port 5000 between server/clients
4. **Discovery**: Clients auto-find server, or configure manually

---

## Features

- 👥 Student management & card assignment
- 💰 Real-time transaction processing
- 📊 Balance tracking & reporting
- 🏷️ RFID card reader support
- 🔒 Kiosk lockdown mode
- 📥 Automatic CSV import via email
- 🌐 Web admin interface
- 🔄 Multi-device synchronization

---

## Quick Troubleshooting

### Server Issues
```bash
# Check if running
curl http://localhost:5000/health

# View logs
classdojo-manage logs
```

### Client Issues
```bash
# Test connection
curl http://[SERVER_IP]:5000/health

# Start in dev mode
cd /opt/classdojo-client && ./start-kiosk.sh --dev
```

### Network Issues
```bash
# Check connectivity
ping [SERVER_IP]

# Allow port 5000
sudo ufw allow 5000/tcp
```

---

## Documentation

- **Full Guide:** [INSTALL.md](INSTALL.md)
- **Server Setup:** [README-COMPREHENSIVE.md](README-COMPREHENSIVE.md)
- **Client Setup:** [client/README.md](client/README.md)

---

## Next Steps

1. ✅ Install server on central machine
2. ✅ Install clients on POS terminals
3. ✅ Configure network connectivity
4. ✅ Import student data on server
5. ✅ Test card transactions
6. ✅ Set up backups

---

**Ready to deploy?** Start with the server installation! 🎉
