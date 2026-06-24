@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0..\.."

REM Check for admin and restart if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell Start-Process -Verb RunAs -FilePath "cmd" -ArgumentList '/c', '"%~f0" %*'
    exit /b 0
)

echo ========================================
echo LANrage Quick Install Script
echo ========================================
echo.

REM Quick installation script for LANrage
REM Uses uv to manage Python and dependencies

REM Step 1: Install uv
echo [1/5] Installing uv package manager...
where uv >nul 2>&1 || (
    start "uv" cmd /k "powershell -ExecutionPolicy Bypass -Command ""try { irm https://astral.sh/uv/install.ps1 | iex; Write-Host 'uv installed successfully!' } catch { Write-Host 'Failed to install uv:' $_.Exception.Message }"" && echo Installation complete. Press any key... && pause && exit"
    echo Press any key after uv installation completes...
    pause >nul
    for /f "tokens=*" %%i in ('where uv 2^>nul') do set "uv_path=%%i"
    if not defined uv_path (
        set "PATH=%USERPROFILE%\.local\bin;%PATH%"
    )
)

REM Step 2: Install Python 3.12 via uv
echo [2/5] Installing Python 3.12...
uv python find 3.12 >nul 2>&1 || (
    start "Python 3.12" cmd /k "uv python install 3.12 && echo Python 3.12 installed! Press any key... && pause && exit"
    echo Press any key after Python installation completes...
    pause >nul
)

REM Step 3: Setup environment
echo [3/5] Setting up LANrage environment...
if not exist ".venv" (
    uv venv --python 3.12 .venv
)
uv sync --extra dev

REM Step 4: Install WireGuard
echo [4/5] Installing WireGuard (if needed)...
.venv\Scripts\python.exe scripts\install_wireguard.py

REM Step 5: Run LANrage
echo [5/5] Starting LANrage...
start "LANrage" cmd /k ".venv\Scripts\python.exe lanrage.py"

echo.
echo LANrage is starting in a new window!
echo Web interface: http://localhost:8666
echo.
pause
exit /b 0