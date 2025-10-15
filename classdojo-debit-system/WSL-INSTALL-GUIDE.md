# 🪟 WSL Ubuntu 24.04 LTS Installation Guide

Simple guide to install Windows Subsystem for Linux (WSL) with Ubuntu 24.04 LTS on Windows.

## 🚀 Quick Install

### Method 1: PowerShell Script (Recommended)

1. **Download the script:**
   - Download `install-wsl.ps1` from this repository

2. **Run as Administrator:**
   - Right-click on `install-wsl.ps1`
   - Select "Run with PowerShell"
   - If prompted, click "Yes" to allow administrator access

3. **Follow the prompts:**
   - The script will check your system
   - Install WSL if needed
   - Download and install Ubuntu 24.04 LTS
   - Launch Ubuntu for initial setup

### Method 2: Batch File

1. **Download the script:**
   - Download `install-wsl.bat` from this repository

2. **Run as Administrator:**
   - Right-click on `install-wsl.bat`
   - Select "Run as administrator"

3. **Follow the prompts:**
   - The script will install WSL and Ubuntu 24.04 LTS

### Method 3: Manual Command (Simplest)

Open PowerShell as Administrator and run:

```powershell
wsl --install -d Ubuntu-24.04
```

---

## 📋 Requirements

### System Requirements
- **Windows 10:** Version 2004 or higher (Build 19041+)
- **Windows 11:** Any version
- **RAM:** 4GB minimum (8GB recommended)
- **Disk Space:** 10GB free space
- **Internet:** Required for download (~500MB)

### Check Your Windows Version
1. Press `Win + R`
2. Type `winver` and press Enter
3. Check the version number

---

## 🎯 What the Scripts Do

### Automated Installation Steps:

1. ✅ **Check Administrator Privileges**
   - Ensures script has necessary permissions

2. ✅ **Verify Windows Version**
   - Confirms Windows 10 2004+ or Windows 11

3. ✅ **Check Existing Installation**
   - Detects if WSL or Ubuntu 24.04 is already installed
   - Offers to reinstall if needed

4. ✅ **Enable WSL Features** (if needed)
   - Enables Windows Subsystem for Linux
   - Enables Virtual Machine Platform
   - May require system restart

5. ✅ **Set WSL 2 as Default**
   - Configures WSL 2 for better performance

6. ✅ **Install Ubuntu 24.04 LTS**
   - Downloads Ubuntu 24.04 from Microsoft Store
   - Installs and configures the distribution

7. ✅ **Launch Ubuntu**
   - Opens Ubuntu for initial user setup

---

## 🔧 Initial Ubuntu Setup

After installation, Ubuntu will launch and prompt you to:

1. **Create a Username**
   - Choose a username (lowercase, no spaces)
   - Example: `john` or `myuser`

2. **Set a Password**
   - Choose a secure password
   - You'll need to type it twice
   - **Important:** Remember this password!

3. **Complete Setup**
   - Ubuntu will finish configuration
   - You'll see a command prompt

---

## 🎮 Using WSL

### Launch Ubuntu

**From Start Menu:**
- Click Start
- Search for "Ubuntu 24.04"
- Click to launch

**From Command Line:**
```cmd
wsl
```

Or specifically:
```cmd
wsl -d Ubuntu-24.04
```

**From Windows Terminal:**
- Open Windows Terminal
- Click the dropdown arrow (˅)
- Select "Ubuntu 24.04"

### Useful WSL Commands

```powershell
# List all installed distributions
wsl --list --verbose

# Launch default distribution
wsl

# Launch specific distribution
wsl -d Ubuntu-24.04

# Shutdown all WSL instances
wsl --shutdown

# Update WSL
wsl --update

# Set default distribution
wsl --set-default Ubuntu-24.04

# Uninstall a distribution
wsl --unregister Ubuntu-24.04
```

---

## 📁 Accessing Windows Files from Ubuntu

Your Windows drives are mounted in Ubuntu:

```bash
# Access C: drive
cd /mnt/c/

# Access your user folder
cd /mnt/c/Users/YourUsername/

# Access Documents
cd /mnt/c/Users/YourUsername/Documents/
```

### Accessing Ubuntu Files from Windows

In File Explorer, type:
```
\\wsl$\Ubuntu-24.04\home\yourusername\
```

Or navigate to:
- Network → WSL$ → Ubuntu-24.04

---

## 🔄 Updating Ubuntu

After installation, update Ubuntu:

```bash
sudo apt update
sudo apt upgrade -y
```

---

## 🆘 Troubleshooting

### "WSL 2 requires an update to its kernel component"

**Solution:**
1. Download the WSL2 kernel update: https://aka.ms/wsl2kernel
2. Install the update
3. Run the installation script again

### "The requested operation requires elevation"

**Solution:**
- Right-click the script
- Select "Run as administrator"

### "This application requires the Windows Subsystem for Linux Optional Component"

**Solution:**
1. Open PowerShell as Administrator
2. Run: `dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart`
3. Restart your computer
4. Run the installation script again

### Installation Hangs or Fails

**Solution:**
1. Open PowerShell as Administrator
2. Run: `wsl --shutdown`
3. Try the installation again

### "Ubuntu 24.04 not found in Microsoft Store"

**Solution:**
- Update Windows to the latest version
- Or install from Microsoft Store manually:
  1. Open Microsoft Store
  2. Search "Ubuntu 24.04 LTS"
  3. Click "Get" or "Install"

### Need to Restart After Installation

**Solution:**
- Some systems require a restart after enabling WSL features
- Restart your computer
- Run the installation script again

---

## 🔒 Security Notes

1. **Password Protection**
   - Your Ubuntu password is separate from Windows
   - Keep it secure and memorable
   - Required for `sudo` commands

2. **Firewall**
   - WSL shares Windows firewall settings
   - Configure Windows Firewall as needed

3. **Updates**
   - Keep Ubuntu updated: `sudo apt update && sudo apt upgrade`
   - Keep Windows updated for WSL improvements

---

## 🎓 Next Steps After Installation

### 1. Update System
```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Install Common Tools
```bash
# Install build essentials
sudo apt install build-essential -y

# Install git
sudo apt install git -y

# Install curl
sudo apt install curl -y
```

### 3. Configure Git (Optional)
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 4. Install Windows Terminal (Recommended)
- Download from Microsoft Store
- Better terminal experience
- Multiple tabs and profiles

---

## 📚 Additional Resources

### Official Documentation
- [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [Ubuntu WSL Guide](https://ubuntu.com/wsl)

### Useful Links
- [WSL GitHub](https://github.com/microsoft/WSL)
- [Ubuntu Documentation](https://help.ubuntu.com/)

---

## 💡 Tips

1. **Use Windows Terminal**
   - Better than Command Prompt or PowerShell
   - Multiple tabs, themes, and profiles

2. **Access Windows Files**
   - Your Windows drives are at `/mnt/c/`, `/mnt/d/`, etc.

3. **Run Windows Programs from WSL**
   ```bash
   explorer.exe .  # Open current directory in File Explorer
   notepad.exe file.txt  # Open file in Notepad
   ```

4. **Copy/Paste in Terminal**
   - Right-click to paste
   - Or use Ctrl+Shift+C/V

5. **Performance**
   - Store project files in Ubuntu filesystem for better performance
   - Use `/home/username/` instead of `/mnt/c/`

---

## 🎉 Installation Complete!

You now have Ubuntu 24.04 LTS running on Windows via WSL!

### Quick Start Commands:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Check Ubuntu version
lsb_release -a

# Check WSL version
wsl --version

# Get help
man <command>
```

---

## 📞 Support

For issues:
1. Check the troubleshooting section above
2. Visit [WSL GitHub Issues](https://github.com/microsoft/WSL/issues)
3. Check [Ubuntu Forums](https://ubuntuforums.org/)

---

**Enjoy your Ubuntu 24.04 LTS on Windows! 🐧🪟**
