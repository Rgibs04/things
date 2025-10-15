# Raspberry Pi 3B Deployment Guide

Complete guide for deploying ClassDojo Debit System on Raspberry Pi 3B running Debian/Raspberry Pi OS.

## 🍓 What You Need

### Hardware
- Raspberry Pi 3B (or 3B+)
- MicroSD card (16GB minimum, 32GB recommended)
- Power supply (5V 2.5A)
- Network connection (Ethernet or WiFi)

### Software
- Raspberry Pi OS (Debian-based) - Latest version
- Internet connection for downloading packages

## 🚀 Automated Installation (Recommended)

### One-Command Setup

The easiest way to get started is using the automated setup script:

```bash
# Download the project to your Raspberry Pi
cd ~
# If you have the files, navigate to the directory
cd classdojo-debit-system

# Make the setup script executable
chmod +x raspberry-pi-setup.sh

# Run the automated setup (requires sudo)
sudo bash raspberry-pi-setup.sh
```

### What the Script Does

The automated script will:
1. ✅ Update system packages
2. ✅ Install Python 3, pip, and dependencies
3. ✅ Install Docker for ARM
4. ✅ Install K3s (lightweight Kubernetes for Raspberry Pi)
5. ✅ Build ARM-compatible Docker image
6. ✅ Generate secure secret key
7. ✅ Deploy application to K3s
8. ✅ Configure automatic startup

**Installation time:** Approximately 15-30 minutes depending on your internet speed.

## 📋 Manual Installation (Alternative)

If you prefer to install manually or need to troubleshoot:

### Step 1: Update System

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### Step 2: Install Dependencies

```bash
sudo apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    python3-venv \
    sqlite3 \
    ca-certificates
```

### Step 3: Install Docker

```bash
# Install Docker for ARM
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add pi user to docker group
sudo usermod -aG docker pi

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
```

### Step 4: Install K3s

```bash
# Install K3s (lightweight Kubernetes)
curl -sfL https://get.k3s.io | sh -s - \
    --write-kubeconfig-mode 644 \
    --disable traefik \
    --disable servicelb

# Wait for K3s to start
sleep 30

# Verify installation
sudo k3s kubectl get nodes
```

### Step 5: Build and Deploy

```bash
# Navigate to project directory
cd ~/classdojo-debit-system

# Build ARM-compatible Docker image
docker build -f Dockerfile.arm -t classdojo-debit-system:latest .

# Import image to K3s
docker save classdojo-debit-system:latest | sudo k3s ctr images import -

# Generate secret key
python3 -c "import secrets; print(secrets.token_hex(32))"
# Copy the output and update k8s/secret.yaml

# Deploy to K3s
sudo k3s kubectl apply -f k8s/namespace.yaml
sudo k3s kubectl apply -f k8s/configmap.yaml
sudo k3s kubectl apply -f k8s/secret.yaml
sudo k3s kubectl apply -f k8s/persistent-volume.yaml
sudo k3s kubectl apply -f k8s/persistent-volume-claim.yaml
sudo k3s kubectl apply -f k8s/deployment.yaml
sudo k3s kubectl apply -f k8s/service.yaml

# Wait for deployment
sudo k3s kubectl wait --for=condition=available --timeout=300s \
    deployment/classdojo-debit-system -n classdojo-system
```

## 🌐 Accessing the Application

### Find Your Raspberry Pi's IP Address

```bash
hostname -I
```

### Access Methods

1. **From the Raspberry Pi itself:**
   ```
   http://localhost:5000
   ```

2. **From another device on the same network:**
   ```
   http://[YOUR_PI_IP]:5000
   ```
   Example: `http://192.168.1.100:5000`

3. **Using port forwarding:**
   ```bash
   sudo k3s kubectl port-forward -n classdojo-system svc/classdojo-service 5000:80
   ```

### Quick Access Command

After automated installation, you can run:
```bash
classdojo-access
```

## 🔧 Management Commands

### View Application Status

```bash
# Check pods
sudo k3s kubectl get pods -n classdojo-system

# Check services
sudo k3s kubectl get svc -n classdojo-system

# View all resources
sudo k3s kubectl get all -n classdojo-system
```

### View Logs

```bash
# View application logs
sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system

# Follow logs in real-time
sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system -f
```

### Restart Application

```bash
sudo k3s kubectl rollout restart deployment/classdojo-debit-system -n classdojo-system
```

### Update Application

```bash
# Rebuild image
cd ~/classdojo-debit-system
docker build -f Dockerfile.arm -t classdojo-debit-system:v2 .

# Import to K3s
docker save classdojo-debit-system:v2 | sudo k3s ctr images import -

# Update deployment
sudo k3s kubectl set image deployment/classdojo-debit-system \
    -n classdojo-system classdojo-app=classdojo-debit-system:v2

# Check rollout status
sudo k3s kubectl rollout status deployment/classdojo-debit-system -n classdojo-system
```

### Stop/Start K3s

```bash
# Stop K3s
sudo systemctl stop k3s

# Start K3s
sudo systemctl start k3s

# Check status
sudo systemctl status k3s

# Enable auto-start on boot
sudo systemctl enable k3s
```

## 💾 Backup and Restore

### Backup Database

```bash
# Get pod name
POD_NAME=$(sudo k3s kubectl get pods -n classdojo-system \
    -l app=classdojo-debit-system -o jsonpath='{.items[0].metadata.name}')

# Copy database
sudo k3s kubectl cp classdojo-system/$POD_NAME:/app/database/school_debit.db \
    ~/backup-$(date +%Y%m%d).db
```

### Restore Database

```bash
# Copy backup to pod
sudo k3s kubectl cp ~/backup.db \
    classdojo-system/$POD_NAME:/app/database/school_debit.db

# Restart application
sudo k3s kubectl rollout restart deployment/classdojo-debit-system -n classdojo-system
```

## 🔒 Security Recommendations

1. **Change Default Password:**
   - If using default Raspberry Pi credentials, change them:
   ```bash
   passwd
   ```

2. **Update Secret Key:**
   - The automated script generates a secure key
   - For manual installation, update `k8s/secret.yaml`

3. **Enable Firewall:**
   ```bash
   sudo apt-get install ufw
   sudo ufw allow 22/tcp  # SSH
   sudo ufw allow 5000/tcp  # Application
   sudo ufw enable
   ```

4. **Keep System Updated:**
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```

## ⚡ Performance Optimization

### For Raspberry Pi 3B

1. **Increase Swap Space:**
   ```bash
   sudo dphys-swapfile swapoff
   sudo nano /etc/dphys-swapfile
   # Change CONF_SWAPSIZE=100 to CONF_SWAPSIZE=1024
   sudo dphys-swapfile setup
   sudo dphys-swapfile swapon
   ```

2. **Reduce Resource Limits:**
   Edit `k8s/deployment.yaml`:
   ```yaml
   resources:
     requests:
       memory: "64Mi"
       cpu: "50m"
     limits:
       memory: "256Mi"
       cpu: "250m"
   ```

3. **Disable Unnecessary Services:**
   ```bash
   sudo systemctl disable bluetooth
   sudo systemctl disable avahi-daemon
   ```

## 🆘 Troubleshooting

### Application Won't Start

```bash
# Check pod status
sudo k3s kubectl describe pod -n classdojo-system -l app=classdojo-debit-system

# Check logs
sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system
```

### Out of Memory

```bash
# Check memory usage
free -h

# Increase swap space (see Performance Optimization)

# Reduce resource limits in deployment.yaml
```

### Can't Access from Network

```bash
# Check if service is running
sudo k3s kubectl get svc -n classdojo-system

# Check firewall
sudo ufw status

# Allow port 5000
sudo ufw allow 5000/tcp
```

### K3s Won't Start

```bash
# Check K3s status
sudo systemctl status k3s

# View K3s logs
sudo journalctl -u k3s -f

# Restart K3s
sudo systemctl restart k3s
```

### Docker Build Fails

```bash
# Check available space
df -h

# Clean up Docker
docker system prune -a

# Use ARM-specific Dockerfile
docker build -f Dockerfile.arm -t classdojo-debit-system:latest .
```

## 📊 System Requirements

### Minimum Requirements
- Raspberry Pi 3B
- 1GB RAM
- 8GB SD card
- Debian/Raspberry Pi OS

### Recommended Requirements
- Raspberry Pi 3B+ or 4
- 2GB+ RAM
- 32GB SD card (Class 10 or better)
- Ethernet connection
- Active cooling

## 🔄 Uninstallation

To completely remove the application:

```bash
# Delete Kubernetes resources
sudo k3s kubectl delete namespace classdojo-system

# Uninstall K3s
sudo /usr/local/bin/k3s-uninstall.sh

# Remove Docker (optional)
sudo apt-get remove docker-ce docker-ce-cli containerd.io

# Remove application files
sudo rm -rf /opt/classdojo
```

## 📚 Additional Resources

- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)
- [K3s Documentation](https://docs.k3s.io/)
- [Docker on ARM](https://www.docker.com/blog/getting-started-with-docker-for-arm-on-linux/)

## 💡 Tips

1. **Use Ethernet:** For better stability, use wired connection instead of WiFi
2. **Monitor Temperature:** Raspberry Pi 3B can get hot under load
   ```bash
   vcgencmd measure_temp
   ```
3. **Regular Backups:** Set up automated database backups
4. **Static IP:** Configure a static IP for easier access
5. **Power Supply:** Use official Raspberry Pi power supply for stability

## 🎯 Next Steps

After installation:
1. Access the web interface
2. Import student data
3. Assign cards to students
4. Test transactions
5. Set up regular backups

---

**Need Help?** Check the main [README.md](README.md) or [DEPLOYMENT.md](DEPLOYMENT.md) for more information.
