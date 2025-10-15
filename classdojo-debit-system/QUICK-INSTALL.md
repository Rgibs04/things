# 🚀 Quick Install - ClassDojo Debit System

## One-Line Installation for Raspberry Pi 3B

### Install Now (Choose One Method)

#### From GitHub (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/classdojo-debit-system/main/install.sh | sudo bash
```

#### Or with wget
```bash
wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/classdojo-debit-system/main/install.sh | sudo bash
```

#### From Local Files
```bash
cd classdojo-debit-system
chmod +x install.sh
sudo bash install.sh
```

---

## What Happens Next?

The installer will:
1. ✅ Check your system (RAM, disk, architecture)
2. ✅ Ask you to choose installation method:
   - **K3s (Kubernetes)** - Production ready, full orchestration
   - **Docker Compose** - Recommended, easy to manage ⭐
   - **Standalone Python** - Minimal resources, no containers
3. ✅ Install all dependencies automatically
4. ✅ Build and deploy the application
5. ✅ Configure automatic startup

**Time:** 15-30 minutes  
**Requirements:** Raspberry Pi 3B+, 512MB+ RAM, 4GB+ free disk

---

## After Installation

### Access Your Application

**From the Raspberry Pi:**
```
http://localhost:5000
```

**From another device:**
```
http://[YOUR_PI_IP]:5000
```

Find your IP:
```bash
hostname -I
```

### Quick Commands

**Docker Compose (Recommended):**
```bash
classdojo-manage start      # Start
classdojo-manage stop       # Stop
classdojo-manage restart    # Restart
classdojo-manage logs       # View logs
classdojo-manage backup     # Backup database
classdojo-manage access     # Show URLs
```

**K3s (Kubernetes):**
```bash
sudo k3s kubectl get pods -n classdojo-system
sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system -f
classdojo-access
```

**Standalone Python:**
```bash
sudo systemctl status classdojo
sudo systemctl restart classdojo
sudo journalctl -u classdojo -f
```

---

## System Requirements

### Minimum
- Raspberry Pi 3B or newer
- 512MB RAM
- 4GB free disk space
- Debian/Raspberry Pi OS
- Internet connection

### Recommended
- Raspberry Pi 3B+ or 4
- 1GB+ RAM
- 8GB+ free disk space
- Ethernet connection
- 32GB SD card (Class 10)

---

## Troubleshooting

### Installation fails?
```bash
# Check requirements
free -h          # RAM
df -h            # Disk space
ping 8.8.8.8     # Internet

# View logs
sudo journalctl -xe
```

### Can't access application?
```bash
# Check if running
docker ps                    # Docker Compose
sudo k3s kubectl get pods    # K3s
sudo systemctl status classdojo  # Standalone

# Check firewall
sudo ufw allow 5000/tcp
```

### Out of memory?
```bash
# Increase swap
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Set CONF_SWAPSIZE=1024
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

---

## Documentation

- **Full Installation Guide:** [INSTALL.md](INSTALL.md)
- **User Guide:** [README.md](README.md)
- **Raspberry Pi Guide:** [RASPBERRY-PI-GUIDE.md](RASPBERRY-PI-GUIDE.md)
- **Quick Start:** [RASPBERRY-PI-QUICKSTART.md](RASPBERRY-PI-QUICKSTART.md)

---

## Features

- 👥 Student management
- 💳 Card assignment
- 💰 Transaction processing
- 📊 Balance tracking
- 📜 Transaction history
- 📥 CSV import
- 🌐 Web interface
- 🔌 REST API

---

## Security Tips

1. Change default Pi password: `passwd`
2. Enable firewall: `sudo ufw enable`
3. Keep system updated: `sudo apt-get update && sudo apt-get upgrade`
4. Set up regular backups: `classdojo-manage backup`
5. Use static IP for easier access

---

## Next Steps

1. ✅ Access web interface
2. ✅ Import student data
3. ✅ Assign cards
4. ✅ Process transactions
5. ✅ Set up backups

---

**Questions?** See [INSTALL.md](INSTALL.md) for detailed documentation.

**Ready to install?** Run the one-liner command above! 🎉
