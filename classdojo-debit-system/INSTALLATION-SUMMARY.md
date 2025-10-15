# 🎯 Installation Summary - ClassDojo Debit System

## Quick Reference Guide for Raspberry Pi 3B Setup

---

## 🚀 Installation Options

### Option 1: One-Line Installer (Easiest) ⭐

**From GitHub:**
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/classdojo-debit-system/main/install.sh | sudo bash
```

**From Local Files:**
```bash
cd classdojo-debit-system
sudo bash install.sh
```

**What it does:**
- Detects your system automatically
- Checks requirements (RAM, disk, architecture)
- Lets you choose installation method
- Installs everything automatically
- Configures auto-start

**Time:** 15-30 minutes

---

### Option 2: Docker Compose (Recommended)

```bash
cd classdojo-debit-system
chmod +x docker-compose-install.sh
sudo bash docker-compose-install.sh
```

**Features:**
- ✅ Easy management with `classdojo-manage` command
- ✅ Automatic restarts
- ✅ Simple backups
- ✅ ~200MB RAM usage
- ✅ Container isolation

**Management:**
```bash
classdojo-manage start      # Start
classdojo-manage stop       # Stop
classdojo-manage restart    # Restart
classdojo-manage logs       # View logs
classdojo-manage backup     # Backup database
```

---

### Option 3: K3s (Kubernetes)

```bash
cd classdojo-debit-system
chmod +x raspberry-pi-setup.sh
sudo bash raspberry-pi-setup.sh
```

**Features:**
- ✅ Production-ready orchestration
- ✅ Auto-healing
- ✅ Easy scaling
- ✅ ~400MB RAM usage
- ✅ Full Kubernetes features

**Management:**
```bash
sudo k3s kubectl get pods -n classdojo-system
sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system -f
classdojo-access
```

---

### Option 4: Standalone Python (Minimal)

```bash
cd classdojo-debit-system
chmod +x standalone-install.sh
sudo bash standalone-install.sh
```

**Features:**
- ✅ No containers
- ✅ Minimal resources (~100MB RAM)
- ✅ Direct Python execution
- ✅ Systemd service
- ✅ Fastest startup

**Management:**
```bash
sudo systemctl status classdojo
sudo systemctl restart classdojo
sudo journalctl -u classdojo -f
```

---

## 📊 Comparison Table

| Feature | One-Liner | Docker Compose | K3s | Standalone |
|---------|-----------|----------------|-----|------------|
| **Ease of Use** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **RAM Usage** | Varies | ~200MB | ~400MB | ~100MB |
| **Disk Usage** | Varies | ~1.5GB | ~2GB | ~500MB |
| **Setup Time** | 15-30 min | 15-20 min | 20-30 min | 10-15 min |
| **Management** | Simple | Simple | Advanced | Simple |
| **Production Ready** | ✅ | ✅ | ⭐⭐⭐ | ✅ |
| **Auto-restart** | ✅ | ✅ | ✅ | ✅ |
| **Isolation** | ✅ | ✅ | ⭐⭐⭐ | ❌ |
| **Scalability** | Limited | Limited | ⭐⭐⭐ | Limited |

---

## 🎯 Which Method Should I Choose?

### Choose **One-Liner Installer** if:
- You want the easiest setup
- You're not sure which method to use
- You want to be guided through the process

### Choose **Docker Compose** if:
- You want easy management
- You need container isolation
- You want simple backups
- You have 1GB+ RAM

### Choose **K3s** if:
- You need production-grade orchestration
- You want auto-healing
- You plan to scale
- You have 1GB+ RAM

### Choose **Standalone Python** if:
- You have limited resources (512MB RAM)
- You don't need containers
- You want minimal overhead
- You're comfortable with systemd

---

## 📋 System Requirements

### Minimum Requirements
- **Hardware:** Raspberry Pi 3B or newer
- **RAM:** 512MB (1GB+ recommended)
- **Disk:** 4GB free (8GB+ recommended)
- **OS:** Debian/Raspberry Pi OS
- **Network:** Internet connection

### Recommended Setup
- **Hardware:** Raspberry Pi 3B+ or 4
- **RAM:** 2GB+
- **Disk:** 32GB SD card (Class 10)
- **Network:** Ethernet connection
- **Cooling:** Heatsink or fan

---

## 🔧 Post-Installation

### Access Your Application

**Local:**
```
http://localhost:5000
```

**Network:**
```
http://[YOUR_PI_IP]:5000
```

**Find IP:**
```bash
hostname -I
```

### First Steps

1. ✅ Access the web interface
2. ✅ Import student data (CSV) or add manually
3. ✅ Assign cards to students
4. ✅ Test a transaction
5. ✅ Set up regular backups

### Security Checklist

- [ ] Change default Pi password: `passwd`
- [ ] Enable firewall: `sudo ufw enable && sudo ufw allow 5000/tcp`
- [ ] Set static IP address
- [ ] Configure regular backups
- [ ] Update system: `sudo apt-get update && sudo apt-get upgrade`

---

## 💾 Backup Commands

### Docker Compose
```bash
classdojo-manage backup
```

### K3s
```bash
POD_NAME=$(sudo k3s kubectl get pods -n classdojo-system -l app=classdojo-debit-system -o jsonpath='{.items[0].metadata.name}')
sudo k3s kubectl cp classdojo-system/$POD_NAME:/app/database/school_debit.db ~/backup-$(date +%Y%m%d).db
```

### Standalone
```bash
classdojo-manage backup
# Or manually:
cp /opt/classdojo/database/school_debit.db ~/backup-$(date +%Y%m%d).db
```

---

## 🆘 Quick Troubleshooting

### Can't access application?
```bash
# Check if running
docker ps                           # Docker Compose
sudo k3s kubectl get pods -n classdojo-system  # K3s
sudo systemctl status classdojo     # Standalone

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

### View logs?
```bash
# Docker Compose
docker-compose -f /opt/classdojo/docker-compose-pi.yml logs -f

# K3s
sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system -f

# Standalone
sudo journalctl -u classdojo -f
```

---

## 📚 Documentation Files

- **[QUICK-INSTALL.md](QUICK-INSTALL.md)** - Quick installation reference
- **[INSTALL.md](INSTALL.md)** - Complete installation guide
- **[README.md](README.md)** - Application user guide
- **[RASPBERRY-PI-GUIDE.md](RASPBERRY-PI-GUIDE.md)** - Detailed Pi guide
- **[RASPBERRY-PI-QUICKSTART.md](RASPBERRY-PI-QUICKSTART.md)** - Quick start guide
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Deployment documentation

---

## 🎉 Installation Complete!

After installation, you should have:
- ✅ Application running on port 5000
- ✅ Auto-start on boot configured
- ✅ Management commands available
- ✅ Secure secret key generated
- ✅ Database initialized

**Next:** Access http://[YOUR_PI_IP]:5000 and start using the system!

---

## 💡 Tips

1. **Use Ethernet** for better stability
2. **Set static IP** for easier access
3. **Regular backups** - Set up daily automated backups
4. **Monitor temperature** - `vcgencmd measure_temp`
5. **Quality SD card** - Use Class 10 or better
6. **Proper power supply** - Use official Raspberry Pi adapter
7. **Cooling** - Consider heatsink/fan for 24/7 operation

---

**Questions?** See the full documentation in [INSTALL.md](INSTALL.md)

**Ready to install?** Choose a method above and get started! 🚀
