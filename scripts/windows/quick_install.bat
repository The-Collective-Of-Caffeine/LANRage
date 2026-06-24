@echo off
setlocal enabledelayedexpansion

echo ========================================
echo LANrage Quick Install Script
echo ========================================
echo.

REM Quick installation script for LANrage
REM Uses standalone uv installer (no Python required for uv itself)

REM Step 1: Install uv (standalone, no Python needed)
echo [1/4] Installing uv package manager...
where uv >nul 2>&1
if %errorLevel% neq 0 (
    echo uv not found. Installing via PowerShell...
    start "Install uv" cmd /k "powershell -ExecutionPolicy Bypass -Command ""try { irm https://astral.sh/uv/install.ps1 | iex; Write-Host 'uv installed successfully!' } catch { Write-Host 'Failed:' $_.Exception.Message; pause; exit 1 }"" && echo Press any key to continue... && pause && exit"
    echo Press any key after uv installation completes...
    pause >nul
    REM Refresh PATH
    for /f "tokens=*" %%i in ('"%USERPROFILE%\.local\bin\uv.exe" version 2^>nul') do set "PATH=%USERPROFILE%\.local\bin;%PATH%"
) else (
    echo uv already installed.
)

echo.

REM Step 2: Ensure Python 3.12 is available
echo [2/4] Checking Python 3.12...
python --version 2>nul | findstr "3.12" >nul
if %errorLevel% neq 0 (
    echo Python 3.12 not found. Installing via uv...
    start "Install Python 3.12" cmd /k "uv python install 3.12 && echo Python 3.12 installed! && echo Press any key to continue... && pause && exit"
    echo Press any key after Python installation completes...
    pause >nul
) else (
    echo Python 3.12 already available.
)

echo.

REM Step 3: Setup virtual environment and install dependencies
echo [3/4] Setting up LANrage environment...
if not exist ".venv" (
    echo Creating virtual environment and installing dependencies...
    start "LANrage Setup" cmd /k "uv venv --python 3.12 && uv sync && .venv\Scripts\python.exe scripts\setup_project.py && echo Setup complete! && echo Press any key to continue... && pause && exit"
    echo Press any key after environment setup completes...
    pause >nul
) else (
    echo Virtual environment exists. Updating dependencies...
    start "LANrage Update" cmd /k "uv sync && echo Update complete! && echo Press any key to continue... && pause && exit"
    echo Press any key after update completes...
    pause >nul
)

echo.

REM Step 4: Run LANrage
echo [4/4] Starting LANrage...
start "LANrage" cmd /k ".venv\Scripts\python.exe lanrage.py"

echo.
echo LANrage is starting in a new window!
echo Web interface: http://localhost:8666
echo.
pause
exit /b 0
