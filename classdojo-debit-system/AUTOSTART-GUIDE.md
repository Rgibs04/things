# 🚀 Auto-Start Configuration Guide

## Overview

The ClassDojo Debit System is configured to **automatically start on system boot** for all installation methods. This ensures your application is always available after a reboot or power cycle.

---

## Auto-Start by Installation Method

### 1. Docker Compose Installation ⭐

**How it works:**
- Systemd service: `classdojo-docker.service`
- Docker Compose restart policy: `unless-stopped`
- **Double protection:** Both systemd and Docker ensure auto-start

**Verification:**
```bash
# Check if systemd service is enabled
sudo systemctl is-enabled classdojo-docker.service

# Check service status
sudo systemctl status classdojo-docker.service

# Check Docker container restart policy
docker inspect classdojo-debit-system | grep -A 5 RestartPolicy
```

**Manual Control:**
```bash
# Enable auto-start (already done during installation)
sudo systemctl enable classdojo-docker.service

# Disable auto-start
sudo systemctl disable classdojo-docker.service

# Start service manually
sudo systemctl start classdojo-docker.service

# Stop service
sudo systemctl stop classdojo-docker.service
```

---

### 2. Standalone Python Installation

**How it works:**
- Systemd service: `classdojo.service`
- Configured with `WantedBy=multi-user.target`
- Automatically enabled during installation

**Verification:**
```bash
# Check if service is enabled
sudo systemctl is-enabled classdojo

# Check service status
sudo systemctl status classdojo

# View service configuration
sudo systemctl cat classdojo
```

**Manual Control:**
```bash
# Enable auto-start (already done during installation)
sudo systemctl enable classdojo

# Disable auto-start
sudo systemctl disable classdojo

# Start service manually
sudo systemctl start classdojo

# Stop service
sudo systemctl stop classdojo

# Restart service
sudo systemctl restart classdojo
```

---

### 3. K3s (Kubernetes) Installation

**How it works:**
- K3s service auto-starts: `k3s.service`
- Kubernetes deployment with restart policy: `Always`
- **Triple protection:** Systemd → K3s → Kubernetes deployment

**Verification:**
```bash
# Check if K3s service is enabled
sudo systemctl is-enabled k3s

# Check K3s status
sudo systemctl status k3s

# Check deployment status
sudo k3s kubectl get deployment -n classdojo-system

# Check pod restart policy
sudo k3s kubectl get deployment classdojo-debit-system -n classdojo-system -o yaml | grep -A 3 restartPolicy
```

**Manual Control:**
```bash
# Enable K3s auto-start (already done during installation)
sudo systemctl enable k3s

# Disable K3s auto-start
sudo systemctl disable k3s

# Start K3s manually
sudo systemctl start k3s

# Stop K3s
sudo systemctl stop k3s

# Restart application only (not K3s)
sudo k3s kubectl rollout restart deployment/classdojo-debit-system -n classdojo-system
```

---

## Testing Auto-Start

### Test 1: Reboot Test
```bash
# Reboot the system
sudo reboot

# After reboot, check if application is running
# For Docker Compose:
docker ps | grep classdojo

# For Standalone Python:
sudo systemctl status classdojo

# For K3s:
sudo k3s kubectl get pods -n classdojo-system
```

### Test 2: Service Restart Test
```bash
# Stop the service
# Docker Compose:
sudo systemctl stop classdojo-docker.service

# Standalone Python:
sudo systemctl stop classdojo

# K3s:
sudo systemctl stop k3s

# Wait a moment, then check if it auto-restarts
sleep 10

# Check status (should show as stopped, not auto-restarted)
# To test auto-start, you need to reboot
```

### Test 3: Application Crash Test
```bash
# For Docker Compose (container will auto-restart):
docker stop classdojo-debit-system
sleep 5
docker ps | grep classdojo  # Should show running again

# For Standalone Python (systemd will restart):
sudo kill -9 $(pgrep -f "python src/app.py")
sleep 15
sudo systemctl status classdojo  # Should show running again

# For K3s (Kubernetes will restart pod):
sudo k3s kubectl delete pod -n classdojo-system -l app=classdojo-debit-system
sleep 10
sudo k3s kubectl get pods -n classdojo-system  # Should show new pod running
```

---

## Troubleshooting Auto-Start

### Application Doesn't Start After Reboot

**Docker Compose:**
```bash
# Check systemd service logs
sudo journalctl -u classdojo-docker.service -n 50

# Check Docker logs
docker logs classdojo-debit-system

# Manually start
sudo systemctl start classdojo-docker.service
```

**Standalone Python:**
```bash
# Check service logs
sudo journalctl -u classdojo -n 50

# Check if service is enabled
sudo systemctl is-enabled classdojo

# Re-enable if needed
sudo systemctl enable classdojo
sudo systemctl start classdojo
```

**K3s:**
```bash
# Check K3s service
sudo systemctl status k3s

# Check pod status
sudo k3s kubectl get pods -n classdojo-system

# Check pod logs
sudo k3s kubectl logs -n classdojo-system -l app=classdojo-debit-system

# Restart K3s
sudo systemctl restart k3s
```

---

### Service Fails to Start

**Check Dependencies:**
```bash
# Docker Compose - ensure Docker is running
sudo systemctl status docker

# Standalone Python - check Python installation
which python3
python3 --version

# K3s - check system resources
free -h
df -h
```

**Check Configuration:**
```bash
# Docker Compose
cat /etc/systemd/system/classdojo-docker.service
docker-compose -f /opt/classdojo/docker-compose.yml config

# Standalone Python
cat /etc/systemd/system/classdojo.service
cat /opt/classdojo/.env

# K3s
sudo k3s kubectl get all -n classdojo-system
```

---

## Boot Order and Timing

### Docker Compose
1. System boots
2. Docker service starts (`docker.service`)
3. Network becomes available (`network-online.target`)
4. ClassDojo Docker service starts (`classdojo-docker.service`)
5. Docker Compose brings up containers
6. Application becomes available (~30 seconds after boot)

### Standalone Python
1. System boots
2. Network becomes available (`network.target`)
3. ClassDojo service starts (`classdojo.service`)
4. Python application initializes
5. Application becomes available (~10 seconds after boot)

### K3s
1. System boots
2. K3s service starts (`k3s.service`)
3. Kubernetes control plane initializes
4. Deployments are reconciled
5. Pods are created and started
6. Application becomes available (~60 seconds after boot)

---

## Advanced Configuration

### Delay Start After Boot

If you want to delay the application start (e.g., wait for other services):

**Docker Compose:**
```bash
sudo systemctl edit classdojo-docker.service
```
Add:
```ini
[Service]
ExecStartPre=/bin/sleep 30
```

**Standalone Python:**
```bash
sudo systemctl edit classdojo
```
Add:
```ini
[Service]
ExecStartPre=/bin/sleep 30
```

### Start Only on Specific Network

**Docker Compose:**
```bash
sudo systemctl edit classdojo-docker.service
```
Add:
```ini
[Unit]
After=network-online.target
Wants=network-online.target
```

### Email Notification on Failure

Install mail utilities:
```bash
sudo apt-get install mailutils
```

Edit service:
```bash
sudo systemctl edit classdojo  # or classdojo-docker.service
```
Add:
```ini
[Service]
OnFailure=failure-notification@%n.service
```

---

## Monitoring Auto-Start

### View Boot Logs
```bash
# All services
sudo journalctl -b

# ClassDojo specific
sudo journalctl -b -u classdojo
sudo journalctl -b -u classdojo-docker.service
sudo journalctl -b -u k3s
```

### Check Boot Time
```bash
# System boot time
systemd-analyze

# Service startup time
systemd-analyze blame | grep classdojo
```

### Real-time Monitoring
```bash
# Watch service status
watch -n 2 'sudo systemctl status classdojo'

# Watch Docker containers
watch -n 2 'docker ps'

# Watch Kubernetes pods
watch -n 2 'sudo k3s kubectl get pods -n classdojo-system'
```

---

## Disabling Auto-Start

If you want to disable auto-start (e.g., for development):

**Docker Compose:**
```bash
sudo systemctl disable classdojo-docker.service
sudo systemctl stop classdojo-docker.service
```

**Standalone Python:**
```bash
sudo systemctl disable classdojo
sudo systemctl stop classdojo
```

**K3s:**
```bash
sudo systemctl disable k3s
sudo systemctl stop k3s
```

To re-enable:
```bash
sudo systemctl enable [service-name]
sudo systemctl start [service-name]
```

---

## Summary

✅ **All installation methods automatically start on boot**
✅ **No manual configuration needed**
✅ **Survives system reboots and power cycles**
✅ **Automatic restart on application crashes**
✅ **Easy to enable/disable as needed**

---

## Quick Reference

| Method | Service Name | Enable Command | Disable Command |
|--------|-------------|----------------|-----------------|
| Docker Compose | `classdojo-docker.service` | `sudo systemctl enable classdojo-docker.service` | `sudo systemctl disable classdojo-docker.service` |
| Standalone Python | `classdojo.service` | `sudo systemctl enable classdojo` | `sudo systemctl disable classdojo` |
| K3s | `k3s.service` | `sudo systemctl enable k3s` | `sudo systemctl disable k3s` |

---

**Need Help?** See [INSTALL.md](INSTALL.md) or [README.md](README.md) for more information.
