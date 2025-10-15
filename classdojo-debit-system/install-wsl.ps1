# WSL Ubuntu 24.04 LTS Installer for Windows
# This script installs WSL with Ubuntu 24.04 LTS
# Run as Administrator: Right-click PowerShell and select "Run as Administrator"
# Requires Windows 10 version 2004+ or Windows 11

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green $args }
function Write-Info { Write-ColorOutput Cyan $args }
function Write-Warning { Write-ColorOutput Yellow $args }
function Write-Error { Write-ColorOutput Red $args }

# Banner
Clear-Host
Write-Info @"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   WSL Ubuntu 24.04 LTS Installer                         ║
║                                                           ║
║   Installing Windows Subsystem for Linux                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "ERROR: This script must be run as Administrator!"
    Write-Warning ""
    Write-Warning "Please:"
    Write-Warning "1. Right-click on PowerShell"
    Write-Warning "2. Select 'Run as Administrator'"
    Write-Warning "3. Run this script again"
    Write-Warning ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Success "✓ Running as Administrator"
Write-Info ""

# Check Windows version
$osVersion = [System.Environment]::OSVersion.Version
$buildNumber = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber

Write-Info "Checking Windows version..."
Write-Info "  Windows Build: $buildNumber"

if ($buildNumber -lt 19041) {
    Write-Error "ERROR: Windows 10 version 2004 (build 19041) or higher is required"
    Write-Warning "Your build: $buildNumber"
    Write-Warning "Please update Windows and try again"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Success "✓ Windows version compatible"
Write-Info ""

# Check if WSL is already installed
Write-Info "Checking if WSL is already installed..."
$wslInstalled = $false
try {
    $wslVersion = wsl --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $wslInstalled = $true
        Write-Success "✓ WSL is already installed"
        Write-Info $wslVersion
    }
} catch {
    Write-Info "  WSL not found, will install"
}
Write-Info ""

# Check if Ubuntu 24.04 is already installed
Write-Info "Checking for existing Ubuntu installations..."
$ubuntuInstalled = $false
try {
    $distributions = wsl --list --verbose 2>$null
    if ($distributions -match "Ubuntu-24.04") {
        $ubuntuInstalled = $true
        Write-Success "✓ Ubuntu 24.04 LTS is already installed!"
        Write-Info ""
        Write-Info "Existing distributions:"
        wsl --list --verbose
        Write-Info ""
        
        $response = Read-Host "Ubuntu 24.04 is already installed. Do you want to reinstall? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Info "Installation cancelled. Exiting..."
            Read-Host "Press Enter to exit"
            exit 0
        }
        
        Write-Warning "Uninstalling existing Ubuntu 24.04..."
        wsl --unregister Ubuntu-24.04
        Write-Success "✓ Uninstalled"
        $ubuntuInstalled = $false
    }
} catch {
    Write-Info "  No existing Ubuntu 24.04 installation found"
}
Write-Info ""

# Install WSL if not already installed
if (-not $wslInstalled) {
    Write-Info "Step 1/3: Installing WSL..."
    Write-Warning "This may take several minutes and require a restart..."
    Write-Info ""
    
    try {
        # Enable WSL feature
        Write-Info "Enabling WSL feature..."
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        
        # Enable Virtual Machine Platform
        Write-Info "Enabling Virtual Machine Platform..."
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
        
        Write-Success "✓ WSL features enabled"
        Write-Info ""
        
        # Check if restart is needed
        Write-Warning "A system restart may be required to complete WSL installation."
        $restart = Read-Host "Do you need to restart now? (y/N)"
        
        if ($restart -eq 'y' -or $restart -eq 'Y') {
            Write-Info ""
            Write-Warning "Please run this script again after restart to complete Ubuntu installation."
            Write-Info ""
            $confirm = Read-Host "Restart now? (y/N)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                Restart-Computer -Force
                exit 0
            } else {
                Write-Info "Please restart manually and run this script again."
                Read-Host "Press Enter to exit"
                exit 0
            }
        }
        
    } catch {
        Write-Error "Failed to enable WSL features: $_"
        Write-Warning "You may need to enable these features manually in Windows Features"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Set WSL 2 as default
Write-Info "Step 2/3: Setting WSL 2 as default version..."
try {
    wsl --set-default-version 2
    Write-Success "✓ WSL 2 set as default"
} catch {
    Write-Warning "Could not set WSL 2 as default. Will try to continue..."
}
Write-Info ""

# Install Ubuntu 24.04 LTS
if (-not $ubuntuInstalled) {
    Write-Info "Step 3/3: Installing Ubuntu 24.04 LTS..."
    Write-Warning "This will download and install Ubuntu 24.04 LTS"
    Write-Warning "Download size: ~500MB"
    Write-Info ""
    
    try {
        # Install Ubuntu 24.04 using wsl --install
        Write-Info "Downloading and installing Ubuntu 24.04 LTS..."
        Write-Info "This may take 5-15 minutes depending on your internet speed..."
        Write-Info ""
        
        wsl --install -d Ubuntu-24.04
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "✓ Ubuntu 24.04 LTS installed successfully!"
        } else {
            throw "Installation failed with exit code $LASTEXITCODE"
        }
        
    } catch {
        Write-Error "Failed to install Ubuntu 24.04: $_"
        Write-Info ""
        Write-Warning "Alternative installation method:"
        Write-Info "1. Open Microsoft Store"
        Write-Info "2. Search for 'Ubuntu 24.04 LTS'"
        Write-Info "3. Click 'Get' or 'Install'"
        Write-Info ""
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Info ""
Write-Success "╔═══════════════════════════════════════════════════════════╗"
Write-Success "║                                                           ║"
Write-Success "║   Installation Complete! 🎉                              ║"
Write-Success "║                                                           ║"
Write-Success "╚═══════════════════════════════════════════════════════════╝"
Write-Info ""

# Show installed distributions
Write-Info "Installed WSL distributions:"
wsl --list --verbose
Write-Info ""

Write-Info "Next Steps:"
Write-Info "1. Ubuntu 24.04 will launch automatically to complete setup"
Write-Info "2. Create a username and password when prompted"
Write-Info "3. After setup, you can launch Ubuntu from:"
Write-Info "   - Start Menu: Search for 'Ubuntu 24.04'"
Write-Info "   - Command: wsl -d Ubuntu-24.04"
Write-Info "   - Windows Terminal: Select Ubuntu 24.04 from dropdown"
Write-Info ""

Write-Info "Useful WSL Commands:"
Write-Info "  wsl                          - Launch default distribution"
Write-Info "  wsl -d Ubuntu-24.04          - Launch Ubuntu 24.04"
Write-Info "  wsl --list --verbose         - List all distributions"
Write-Info "  wsl --shutdown               - Shutdown all distributions"
Write-Info "  wsl --update                 - Update WSL"
Write-Info ""

Write-Success "Installation completed successfully!"
Write-Info ""

# Ask if user wants to launch Ubuntu now
$launch = Read-Host "Would you like to launch Ubuntu 24.04 now? (Y/n)"
if ($launch -ne 'n' -and $launch -ne 'N') {
    Write-Info ""
    Write-Info "Launching Ubuntu 24.04 LTS..."
    Write-Info "Please complete the initial setup (username and password)"
    Write-Info ""
    Start-Sleep -Seconds 2
    wsl -d Ubuntu-24.04
}

Write-Info ""
Read-Host "Press Enter to exit"
