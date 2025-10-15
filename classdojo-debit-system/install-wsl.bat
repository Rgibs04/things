@echo off
REM WSL Ubuntu 24.04 LTS Installer for Windows
REM Run as Administrator: Right-click and select "Run as Administrator"
REM Requires Windows 10 version 2004+ or Windows 11

setlocal enabledelayedexpansion

REM Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ========================================
    echo ERROR: Administrator privileges required
    echo ========================================
    echo.
    echo Please right-click this file and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

cls
echo ╔═══════════════════════════════════════════════════════════╗
echo ║                                                           ║
echo ║   WSL Ubuntu 24.04 LTS Installer                         ║
echo ║                                                           ║
echo ║   Installing Windows Subsystem for Linux                 ║
echo ║                                                           ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.

echo [✓] Running as Administrator
echo.

REM Check if WSL is installed
echo Checking if WSL is installed...
wsl --version >nul 2>&1
if %errorLevel% equ 0 (
    echo [✓] WSL is already installed
    wsl --version
) else (
    echo [i] WSL not found, will install
)
echo.

REM Check if Ubuntu 24.04 is already installed
echo Checking for existing Ubuntu installations...
wsl --list >nul 2>&1
if %errorLevel% equ 0 (
    wsl --list | findstr /C:"Ubuntu-24.04" >nul 2>&1
    if !errorLevel! equ 0 (
        echo [✓] Ubuntu 24.04 LTS is already installed!
        echo.
        wsl --list --verbose
        echo.
        set /p "reinstall=Ubuntu 24.04 is already installed. Reinstall? (y/N): "
        if /i "!reinstall!"=="y" (
            echo.
            echo Uninstalling existing Ubuntu 24.04...
            wsl --unregister Ubuntu-24.04
            echo [✓] Uninstalled
        ) else (
            echo Installation cancelled.
            pause
            exit /b 0
        )
    )
)
echo.

REM Install WSL and Ubuntu 24.04
echo ========================================
echo Installing WSL with Ubuntu 24.04 LTS
echo ========================================
echo.
echo This will:
echo  1. Enable WSL features (if needed)
echo  2. Set WSL 2 as default
echo  3. Download and install Ubuntu 24.04 LTS (~500MB)
echo.
echo This may take 5-15 minutes depending on your internet speed.
echo A system restart may be required.
echo.
pause

echo.
echo Installing WSL with Ubuntu 24.04 LTS...
echo Please wait...
echo.

wsl --install -d Ubuntu-24.04

if %errorLevel% equ 0 (
    echo.
    echo [✓] Installation completed successfully!
) else (
    echo.
    echo [!] Installation encountered an issue
    echo.
    echo If WSL features need to be enabled, a restart may be required.
    echo After restart, run this script again to complete installation.
    echo.
    echo Alternative: Install from Microsoft Store
    echo  1. Open Microsoft Store
    echo  2. Search for "Ubuntu 24.04 LTS"
    echo  3. Click "Get" or "Install"
    echo.
    pause
    exit /b 1
)

echo.
echo ╔═══════════════════════════════════════════════════════════╗
echo ║                                                           ║
echo ║   Installation Complete! 🎉                              ║
echo ║                                                           ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.

REM Show installed distributions
echo Installed WSL distributions:
wsl --list --verbose
echo.

echo Next Steps:
echo  1. Ubuntu 24.04 will launch to complete setup
echo  2. Create a username and password when prompted
echo  3. Launch Ubuntu from:
echo     - Start Menu: Search for "Ubuntu 24.04"
echo     - Command: wsl -d Ubuntu-24.04
echo     - Windows Terminal: Select Ubuntu 24.04
echo.

echo Useful WSL Commands:
echo   wsl                          - Launch default distribution
echo   wsl -d Ubuntu-24.04          - Launch Ubuntu 24.04
echo   wsl --list --verbose         - List all distributions
echo   wsl --shutdown               - Shutdown all distributions
echo   wsl --update                 - Update WSL
echo.

set /p "launch=Launch Ubuntu 24.04 now? (Y/n): "
if /i not "!launch!"=="n" (
    echo.
    echo Launching Ubuntu 24.04 LTS...
    echo Please complete the initial setup (username and password)
    echo.
    timeout /t 2 >nul
    start wsl -d Ubuntu-24.04
)

echo.
pause
