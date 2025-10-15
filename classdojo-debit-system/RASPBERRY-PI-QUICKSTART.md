# 🍓 Raspberry Pi 3B Quick Start

Get ClassDojo Debit System running on your Raspberry Pi 3B in under 30 minutes!

## ⚡ Super Quick Setup (One Command)

```bash
# Copy the project to your Raspberry Pi, then run:
cd classdojo-debit-system
chmod +x raspberry-pi-setup.sh
sudo bash raspberry-pi-setup.sh
```

**That's it!** The script will automatically:
- Install all dependencies
- Set up Docker and K3s
- Build and deploy the application
- Generate secure credentials

## 📋 Prerequisites

- ✅ Raspberry Pi 3B (or 3B+)
- ✅ Raspberry Pi OS (Debian-based) installed
- ✅ Internet connection
- ✅ 16GB+ SD card

## 🌐 Access Your Application

After installation completes, access the application:

### From the Raspberry Pi:
```
http://localhost:5000
```

### From another device on your network:
```
http://[YOUR_PI_IP]:5000
```

To find your Pi's IP address:
```bash
hostname -I
```

Or simply run:
```bash
classdojo-access
```

## 🔧 Quick Commands

```bash
# View application status
sudo k3s kubectl get pods -n classdojo-system

# View logs
sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system -f

# Restart application
sudo k3s kubectl rollout restart deployment/classdojo-debit-system -n classdojo-system

# Stop K3s
sudo systemctl stop k3s

# Start K3s
sudo systemctl start k3s
```

## 💾 Backup Database

```bash
POD_NAME=$(sudo k3s kubectl get pods -n classdojo-system -l app=classdojo-debit-system -o jsonpath='{.items[0].metadata.name}')
sudo k3s kubectl cp classdojo-system/$POD_NAME:/app/database/school_debit.db ~/backup-$(date +%Y%m%d).db
```

## 🆘 Troubleshooting

### Application won't start?
```bash
sudo k3s kubectl describe pod -n classdojo-system -l app=classdojo-debit-system
sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system
```

### Can't access from network?
```bash
# Allow port 5000 through firewall
sudo ufw allow 5000/tcp
```

### Out of memory?
```bash
# Increase swap space
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Change CONF_SWAPSIZE to 1024
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

## 📚 Need More Help?

- **Detailed Guide:** [RASPBERRY-PI-GUIDE.md](RASPBERRY-PI-GUIDE.md)
- **Full Documentation:** [DEPLOYMENT.md](DEPLOYMENT.md)
- **Application Info:** [README.md](README.md)

## 🎯 What Gets Installed

- **Docker** - Container runtime
- **K3s** - Lightweight Kubernetes (perfect for Raspberry Pi)
- **ClassDojo App** - Your debit card system
- **SQLite Database** - Student and transaction data

## ⚙️ System Resources

The application uses:
- ~200MB RAM
- ~2GB disk space
- Minimal CPU when idle

## 🔒 Security Notes

- ✅ Secure secret key auto-generated
- ✅ Database stored in persistent volume
- ⚠️ Change default Pi password: `passwd`
- ⚠️ Enable firewall: `sudo ufw enable`

## 🚀 Next Steps

1. Access the web interface
2. Add students manually or import CSV
3. Assign cards to students
4. Start processing transactions!

---

**Installation Time:** 15-30 minutes (depending on internet speed)

**Questions?** See the full [Raspberry Pi Guide](RASPBERRY-PI-GUIDE.md)
