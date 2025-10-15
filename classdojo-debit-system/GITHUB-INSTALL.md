# 🚀 Install ClassDojo Debit System from GitHub

Complete guide for installing directly from GitHub on Raspberry Pi 3B, Ubuntu, or any Debian-based system.

---

## ⚡ One-Line Installation (Easiest)

### For Ubuntu/Debian (including WSL):
```bash
curl -sSL https://raw.githubusercontent.com/Rgibs04/things/master/classdojo-debit-system/bootstrap.sh | sudo bash
```

### Or with wget:
```bash
wget -qO- https://raw.githubusercontent.com/Rgibs04/things/master/classdojo-debit-system/bootstrap.sh | sudo bash
```

**That's it!** The bootstrap script will:
1. ✅ Detect your system (Raspberry Pi, Ubuntu, Debian)
2. ✅ Install git if needed
3. ✅ Download the entire project from GitHub
4. ✅ Run the appropriate installer for your system
5. ✅ Install all dependencies automatically
6. ✅ Configure autostart on boot
7. ✅ Clean up temporary files

**Installation time:** 15-30 minutes

---

## 📦 What Gets Installed

The installer automatically downloads and installs:

### System Dependencies:
- ✅ Git (if not present)
- ✅ Python 3 and pip
- ✅ Docker and Docker Compose (for Docker method)
- ✅ K3s (for Kubernetes method)
- ✅ SQLite3
- ✅ Required system libraries

### Application Components:
- ✅ Flask web application
- ✅ Database system (SQLite)
- ✅ Web interface (HTML/CSS/JS)
- ✅ API endpoints
- ✅ Management scripts
- ✅ Systemd services for autostart

### Configuration:
- ✅ Secure secret key generation
- ✅ Docker Compose configuration
- ✅ Systemd service files
- ✅ Autostart configuration
- ✅ Management commands

---

## 🎯 Installation Methods

After running the bootstrap script, you'll be asked to choose:

### 1. Docker Compose (Recommended) ⭐
- **Best for:** Most users
- **Resources:** ~200MB RAM, 1.5GB disk
- **Management:** Simple commands (`classdojo-manage`)
- **Autostart:** Systemd + Docker restart policy

### 2. Standalone Python
- **Best for:** Minimal resources
- **Resources:** ~100MB RAM, 500MB disk
- **Management:** Systemd commands
- **Autostart:** Systemd service

### 3. K3s (Kubernetes)
- **Best for:** Production deployments
- **Resources:** ~400MB RAM, 2GB disk
- **Management:** kubectl commands
- **Autostart:** K3s service + Kubernetes

---

## 📋 System Requirements

### Minimum:
- **Device:** Raspberry Pi 3B or any x86_64/ARM system
- **OS:** Debian, Ubuntu, Raspberry Pi OS
- **RAM:** 512MB
- **Disk:** 4GB free space
- **Network:** Internet connection

### Recommended:
- **Device:** Raspberry Pi 3B+ or 4, or modern x86_64 system
- **OS:** Ubuntu 24.04 LTS or Raspberry Pi OS (latest)
- **RAM:** 1GB+
- **Disk:** 8GB+ free space
- **Network:** Ethernet connection

---

## 🔧 Manual Installation from GitHub

If you prefer to clone and install manually:

### Step 1: Clone the Repository
```bash
git clone https://github.com/Rgibs04/things.git
cd things/classdojo-debit-system
```

### Step 2: Choose Your Installer

**For Ubuntu/Debian x86_64:**
```bash
chmod +x ubuntu-install.sh
sudo bash ubuntu-install.sh
```

**For Raspberry Pi:**
```bash
chmod +x raspberry-pi-setup.sh
sudo bash raspberry-pi-setup.sh
```

**For Generic Debian:**
```bash
chmod +x install.sh
sudo bash install.sh
```

---

## 🌐 After Installation

### Access Your Application

**From the same device:**
```
http://localhost:5000
```

**From another device on your network:**
```
http://[YOUR_IP]:5000
```

**Find your IP address:**
```bash
hostname -I
```

### Quick Commands

**Docker Compose Installation:**
```bash
classdojo-manage start      # Start application
classdojo-manage stop       # Stop application
classdojo-manage restart    # Restart application
classdojo-manage logs       # View logs
classdojo-manage status     # Check status
classdojo-manage backup     # Backup database
classdojo-manage access     # Show access URLs
```

**Standalone Python Installation:**
```bash
sudo systemctl start classdojo
sudo systemctl stop classdojo
sudo systemctl restart classdojo
sudo systemctl status classdojo
sudo journalctl -u classdojo -f  # View logs
```

**K3s Installation:**
```bash
sudo k3s kubectl get pods -n classdojo-system
sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system -f
sudo k3s kubectl rollout restart deployment/classdojo-debit-system -n classdojo-system
```

---

## ✅ Autostart Verification

The application is configured to start automatically on boot. To verify:

### Docker Compose:
```bash
# Check systemd service
sudo systemctl status classdojo-docker.service

# Check if enabled
sudo systemctl is-enabled classdojo-docker.service

# Check container
docker ps | grep classdojo
```

### Standalone Python:
```bash
# Check systemd service
sudo systemctl status classdojo.service

# Check if enabled
sudo systemctl is-enabled classdojo.service
```

### K3s:
```bash
# Check K3s service
sudo systemctl status k3s

# Check pods
sudo k3s kubectl get pods -n classdojo-system
```

---

## 🔄 Updating from GitHub

To update to the latest version:

### Docker Compose:
```bash
cd /opt/classdojo
git pull origin master
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Standalone Python:
```bash
cd /opt/classdojo
git pull origin master
sudo systemctl restart classdojo
```

### K3s:
```bash
cd /opt/classdojo
git pull origin master
docker build -t classdojo-debit-system:latest .
docker save classdojo-debit-system:latest | sudo k3s ctr images import -
sudo k3s kubectl rollout restart deployment/classdojo-debit-system -n classdojo-system
```

---

## 🆘 Troubleshooting

### Bootstrap Script Fails

**Check internet connection:**
```bash
ping -c 4 github.com
```

**Check git installation:**
```bash
git --version
```

**Run with verbose output:**
```bash
curl -sSL https://raw.githubusercontent.com/Rgibs04/things/master/classdojo-debit-system/bootstrap.sh | sudo bash -x
```

### Installation Fails

**Check system requirements:**
```bash
free -h          # Check RAM
df -h            # Check disk space
uname -m         # Check architecture
```

**View installation logs:**
```bash
# Check system logs
sudo journalctl -xe

# Check Docker logs (if applicable)
docker logs classdojo-debit-system
```

### Can't Access Application

**Check if service is running:**
```bash
# Docker Compose
docker ps | grep classdojo

# Standalone
sudo systemctl status classdojo

# K3s
sudo k3s kubectl get pods -n classdojo-system
```

**Check firewall:**
```bash
sudo ufw status
sudo ufw allow 5000/tcp
```

**Check port availability:**
```bash
sudo netstat -tulpn | grep 5000
```

---

## 🔒 Security Notes

### After Installation:

1. **Change default passwords:**
   ```bash
   passwd  # Change your user password
   ```

2. **Enable firewall:**
   ```bash
   sudo apt-get install ufw
   sudo ufw allow 22/tcp   # SSH
   sudo ufw allow 5000/tcp # Application
   sudo ufw enable
   ```

3. **Keep system updated:**
   ```bash
   sudo apt-get update
   sudo apt-get upgrade -y
   ```

4. **Secure SSH (if using):**
   ```bash
   sudo nano /etc/ssh/sshd_config
   # Set: PermitRootLogin no
   # Set: PasswordAuthentication no (use SSH keys)
   sudo systemctl restart sshd
   ```

---

## 📚 Additional Resources

- **Complete Installation Guide:** [INSTALL.md](INSTALL.md)
- **Quick Start Guide:** [QUICK-INSTALL.md](QUICK-INSTALL.md)
- **Autostart Guide:** [AUTOSTART-GUIDE.md](AUTOSTART-GUIDE.md)
- **User Manual:** [README.md](README.md)
- **Raspberry Pi Guide:** [RASPBERRY-PI-GUIDE.md](RASPBERRY-PI-GUIDE.md)

---

## 🎯 Quick Reference

### One-Line Install:
```bash
curl -sSL https://raw.githubusercontent.com/Rgibs04/things/master/classdojo-debit-system/bootstrap.sh | sudo bash
```

### Access Application:
```
http://localhost:5000
```

### Management:
```bash
classdojo-manage [start|stop|restart|logs|status|backup|access]
```

### Update:
```bash
cd /opt/classdojo && git pull && docker compose restart
```

---

## ✨ Features

- 👥 Student management
- 💳 Card assignment
- 💰 Transaction processing
- 📊 Balance tracking
- 📜 Transaction history
- 📥 CSV import
- 🌐 Web interface
- 🔌 REST API
- 🔄 Automatic startup
- 💾 Automatic backups

---

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the documentation files
3. Check system logs
4. Visit the GitHub repository: https://github.com/Rgibs04/things

---

**Installation Time:** 15-30 minutes  
**Difficulty:** Easy (fully automated)  
**Recommended:** One-line installation via bootstrap script

**Happy Installing! 🎉**
