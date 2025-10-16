# ClassDojo Debit System

## Overview
This project provides a complete ClassDojo Debit System, including server and client (kiosk) applications. It is designed for easy deployment on Ubuntu (including 24.04+) and Raspberry Pi systems, with support for both standalone and containerized setups.

## Features
- Web-based admin and kiosk UIs
- RFID reader integration for POS terminals
- Auto-discovery and manual server configuration for clients
- Systemd service support for automatic startup
- Virtual environment support for Python dependencies

## Directory Structure
- `src/` — Server application (Flask)
- `client/` — Kiosk client application
- `database/` — Database files
- `templates/` — HTML templates for web UIs
- `static/` — Static assets (CSS, JS, images)
- `k8s/` — Kubernetes deployment files
- `*.sh` — Install and setup scripts

## Quick Start (Ubuntu 24.04+)
1. **Clone the repository:**
   ```bash
   git clone https://github.com/Rgibs04/things.git
   cd things/classdojo-debit-system/classdojo-debit-system
   ```
2. **Run the install script:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
   - For client-only: `./install-client.sh`
   - For server-only: `./install-server.sh`
   - For standalone Pi: `./standalone-install.sh`

3. **(If needed) Manually set up Python venv:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

4. **Start the server:**
   ```bash
   cd src
   python3 app.py
   # or
   python3 app_enhanced.py
   ```

5. **Start the client:**
   ```bash
   cd client
   python3 kiosk_app.py
   # or
   ./start-kiosk.sh --dev
   ```

6. **Access the web UIs:**
   - Server: `http://<server-ip>:<port>`
   - Client: `http://<client-ip>:<port>`

## Troubleshooting
- **Python package errors:** Always use a virtual environment. Never use `sudo pip`.
- **cdrom APT error:** Remove or comment out `cdrom` lines in `/etc/apt/sources.list`.
- **Permission errors:** Do not use `sudo` inside a venv. Delete and recreate the venv if needed.
- **Missing requirements.txt:** Make sure you are in the correct directory.

## Documentation
- `README.md` — Project overview
- `QUICK-INSTALL.md` — Fast install guide
- `INSTALL.md` — Detailed install instructions
- `AUTOSTART-GUIDE.md` — Auto-start setup
- `RASPBERRY-PI-GUIDE.md` — Pi-specific setup
- `COMPLETE-SETUP-SUMMARY.md` — Full setup summary

## Support
If you encounter issues, please provide error messages and your OS version for faster help.
