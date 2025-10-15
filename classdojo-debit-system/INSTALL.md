# 🚀 ClassDojo Debit System - Installation Guide

Complete installation guide for Raspberry Pi 3B running Debian/Raspberry Pi OS.

## 📋 Quick Start

### One-Line Installation (Easiest)

Choose your preferred method and run ONE of these commands:

#### Method 1: From GitHub (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/classdojo-debit-system/main/install.sh | sudo bash
```

Or with wget:
```bash
wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/classdojo-debit-system/main/install.sh | sudo bash
```

#### Method 2: From Local Files
```bash
cd classdojo-debit-system
chmod +x install.sh
sudo bash install.sh
```

**That's it!** The installer will:
- ✅ Detect your system automatically
- ✅ Check system requirements
- ✅ Let you choose installation method
- ✅ Install all dependencies
- ✅ Set up and start the application
- ✅ Configure automatic startup

**Installation time:** 15-30 minutes (depending on internet speed and method chosen)

---

## 🎯 Installation Methods

The installer offers three installation methods:

### 1. K3s (Kubernetes) - Production Ready
- **Best for:** Production deployments, scalability
- **Resources:** ~400MB RAM, 2GB disk
- **Features:** Full Kubernetes orchestration, auto-healing, easy scaling
- **Management:** kubectl commands

### 2. Docker Compose - Recommended ⭐
- **Best for:** Most users, simple deployments
- **Resources:** ~200MB RAM, 1.5GB disk
- **Features:** Easy management, automatic restarts, simple backups
- **Management:** Simple CLI commands

### 3. Standalone Python - Minimal
- **Best for:** Development, minimal resource usage
- **Resources:** ~100MB RAM, 500MB disk
- **Features:** Direct Python execution, no containers
- **Management:** systemd service

---

## 📦 What You Need

### Hardware Requirements
- ✅ Raspberry Pi 3B or 3B+ (or newer)
- ✅ 16GB+ microSD card (32GB recommended)
- ✅ 5V 2.5A power supply
- ✅ Network connection (Ethernet recommended)

### Software Requirements
- ✅ Raspberry Pi OS (Debian-based) - Latest version
- ✅ Internet connection
- ✅ SSH access (if installing remotely)

### Minimum System Requirements
- **RAM:** 512MB minimum, 1GB+ recommended
- **Disk:** 4GB free space minimum, 8GB+ recommended
- **CPU:** ARM v7 or v8 architecture

---

## 🔧 Installation Process

### Step 1: Prepare Your Raspberry Pi

1. **Flash Raspberry Pi OS:**
   - Download [Raspberry Pi Imager](https://www.raspberrypi.org/software/)
   - Flash Raspberry Pi OS (32-bit or 64-bit) to your SD card
   - Enable SSH if needed

2. **Boot and Update:**
   ```bash
   sudo apt-get update
   sudo apt-get upgrade -y
   ```

3. **Set Static IP (Optional but Recommended):**
   ```bash
   sudo nano /etc/dhcpcd.conf
   ```
   Add:
   ```
   interface eth0
   static ip_address=192.168.1.100/24
   static routers=192.168.1.1
   static domain_name_servers=192.168.1.1 8.8.8.8
   ```

### Step 2: Download the Installer

Choose one method:

**Option A: Direct Download**
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/classdojo-debit-system/main/install.sh -o install.sh
chmod +x install.sh
```

**Option B: Clone Repository**
```bash
git clone https://github.com/YOUR_USERNAME/classdojo-debit-system.git
cd classdojo-debit-system
chmod +x install.sh
```

**Option C: Manual Download**
- Download the repository as ZIP
- Extract to your Raspberry Pi
- Navigate to the directory

### Step 3: Run the Installer

```bash
sudo bash install.sh
```

The installer will:
1. ✅ Detect your system
2. ✅ Run pre-flight checks
3. ✅ Ask you to choose installation method
4. ✅ Confirm installation details
5. ✅ Install all components
6. ✅ Configure and start the application

### Step 4: Access Your Application

After installation completes, access the web interface:

**From the Raspberry Pi:**
```
http://localhost:5000
```

**From another device on your network:**
```
http://[YOUR_PI_IP]:5000
```

To find your Pi's IP:
```bash
hostname -I
```

---

## 🎮 Managing Your Installation

### Docker Compose Installation

If you chose Docker Compose, use these commands:

```bash
# Quick management
classdojo-manage start      # Start the application
classdojo-manage stop       # Stop the application
classdojo-manage restart    # Restart the application
classdojo-manage logs       # View logs
classdojo-manage status     # Check status
classdojo-manage backup     # Backup database
classdojo-manage access     # Show access URLs
classdojo-manage update     # Update application

# Direct Docker Compose commands
cd /opt/classdojo
docker-compose -f docker-compose-pi.yml logs -f
docker-compose -f docker-compose-pi.yml restart
docker-compose -f docker-compose-pi.yml down
docker-compose -f docker-compose-pi.yml up -d
```

### K3s (Kubernetes) Installation

If you chose K3s, use these commands:

```bash
# View status
sudo k3s kubectl get pods -n classdojo-system
sudo k3s kubectl get svc -n classdojo-system

# View logs
sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system -f

# Restart application
sudo k3s kubectl rollout restart deployment/classdojo-debit-system -n classdojo-system

# Access information
classdojo-access
```

### Standalone Python Installation

If you chose standalone Python, use these commands:

```bash
# Service management
sudo systemctl start classdojo
sudo systemctl stop classdojo
sudo systemctl restart classdojo
sudo systemctl status classdojo

# View logs
sudo journalctl -u classdojo -f

# Manual start (for testing)
cd /opt/classdojo
source venv/bin/activate
python src/app.py
```

---

## 💾 Backup and Restore

### Automatic Backup (Docker Compose)

```bash
# Create backup
classdojo-manage backup

# Restore from backup
classdojo-manage restore /path/to/backup.db
```

### Manual Backup

**Docker Compose:**
```bash
docker cp classdojo-debit-system:/app/database/school_debit.db ~/backup-$(date +%Y%m%d).db
```

**K3s:**
```bash
POD_NAME=$(sudo k3s kubectl get pods -n classdojo-system -l app=classdojo-debit-system -o jsonpath='{.items[0].metadata.name}')
sudo k3s kubectl cp classdojo-system/$POD_NAME:/app/database/school_debit.db ~/backup-$(date +%Y%m%d).db
```

**Standalone:**
```bash
cp /opt/classdojo/database/school_debit.db ~/backup-$(date +%Y%m%d).db
```

### Automated Daily Backups

Create a cron job:
```bash
crontab -e
```

Add this line:
```
0 2 * * * /usr/local/bin/classdojo-manage backup
```

---

## 🔒 Security Recommendations

### 1. Change Default Passwords
```bash
# Change Pi user password
passwd

# Change root password (if enabled)
sudo passwd root
```

### 2. Enable Firewall
```bash
sudo apt-get install ufw
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 5000/tcp # Application
sudo ufw enable
```

### 3. Update Regularly
```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### 4. Secure SSH
Edit `/etc/ssh/sshd_config`:
```bash
PermitRootLogin no
PasswordAuthentication no  # Use SSH keys
```

### 5. Keep Application Updated
```bash
# Docker Compose
classdojo-manage update

# K3s
cd /opt/classdojo
git pull
docker build -f Dockerfile.arm -t classdojo-debit-system:latest .
docker save classdojo-debit-system:latest | sudo k3s ctr images import -
sudo k3s kubectl rollout restart deployment/classdojo-debit-system -n classdojo-system
```

---

## 🆘 Troubleshooting

### Installation Fails

**Check system requirements:**
```bash
free -h          # Check RAM
df -h            # Check disk space
uname -m         # Check architecture
```

**Check internet connection:**
```bash
ping -c 4 8.8.8.8
```

**View installation logs:**
```bash
# Check system logs
sudo journalctl -xe

# Check Docker logs (if applicable)
docker logs classdojo-debit-system
```

### Application Won't Start

**Docker Compose:**
```bash
docker-compose -f /opt/classdojo/docker-compose-pi.yml logs
docker-compose -f /opt/classdojo/docker-compose-pi.yml ps
```

**K3s:**
```bash
sudo k3s kubectl describe pod -n classdojo-system -l app=classdojo-debit-system
sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system
```

**Standalone:**
```bash
sudo journalctl -u classdojo -n 50
sudo systemctl status classdojo
```

### Can't Access from Network

**Check if service is running:**
```bash
curl http://localhost:5000
```

**Check firewall:**
```bash
sudo ufw status
sudo ufw allow 5000/tcp
```

**Check IP address:**
```bash
hostname -I
ip addr show
```

### Out of Memory

**Increase swap space:**
```bash
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Change CONF_SWAPSIZE to 1024
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

**Check memory usage:**
```bash
free -h
top
htop  # Install with: sudo apt-get install htop
```

### Database Issues

**Reset database:**
```bash
# Backup first!
classdojo-manage backup

# Remove database (will be recreated)
docker exec classdojo-debit-system rm /app/database/school_debit.db
docker-compose -f /opt/classdojo/docker-compose-pi.yml restart
```

---

## 🔄 Uninstallation

### Remove Application Only

**Docker Compose:**
```bash
docker-compose -f /opt/classdojo/docker-compose-pi.yml down
sudo rm -rf /opt/classdojo
sudo rm /usr/local/bin/classdojo-manage
sudo systemctl disable classdojo-docker.service
sudo rm /etc/systemd/system/classdojo-docker.service
```

**K3s:**
```bash
sudo k3s kubectl delete namespace classdojo-system
sudo rm -rf /opt/classdojo
sudo rm /usr/local/bin/classdojo-access
```

**Standalone:**
```bash
sudo systemctl stop classdojo
sudo systemctl disable classdojo
sudo rm /etc/systemd/system/classdojo.service
sudo rm -rf /opt/classdojo
```

### Complete Removal (Including Docker/K3s)

```bash
# Remove Docker
sudo apt-get purge docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker

# Remove K3s
sudo /usr/local/bin/k3s-uninstall.sh

# Remove application
sudo rm -rf /opt/classdojo
```

---

## 📚 Additional Resources

- **User Guide:** [README.md](README.md)
- **Raspberry Pi Guide:** [RASPBERRY-PI-GUIDE.md](RASPBERRY-PI-GUIDE.md)
- **Quick Start:** [RASPBERRY-PI-QUICKSTART.md](RASPBERRY-PI-QUICKSTART.md)
- **Deployment Guide:** [DEPLOYMENT.md](DEPLOYMENT.md)

---

## 💡 Tips and Best Practices

1. **Use Ethernet:** More stable than WiFi for server applications
2. **Static IP:** Makes accessing the application easier
3. **Regular Backups:** Set up automated daily backups
4. **Monitor Temperature:** Raspberry Pi 3B can get hot
   ```bash
   vcgencmd measure_temp
   ```
5. **Use Quality SD Card:** Class 10 or better for better performance
6. **Power Supply:** Use official Raspberry Pi power supply
7. **Cooling:** Consider a heatsink or fan for 24/7 operation

---

## 🎯 Next Steps

After installation:

1. ✅ Access the web interface
2. ✅ Import student data (CSV) or add manually
3. ✅ Assign cards to students
4. ✅ Test transactions
5. ✅ Set up regular backups
6. ✅ Configure firewall rules
7. ✅ Update default passwords

---

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the documentation files
3. Check system logs
4. Contact your system administrator

---

**Installation Time:** 15-30 minutes  
**Difficulty:** Easy (automated) to Moderate (manual)  
**Recommended Method:** Docker Compose via one-line installer

**Happy Installing! 🎉**
