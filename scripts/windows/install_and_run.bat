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
echo LANrage Complete Installation Script
echo ========================================
echo.

echo.
echo Step 1: Installing uv package manager...

where uv >nul 2>&1
if %errorLevel% neq 0 (
    echo uv not found. Installing in new terminal...
    start "Installing uv" cmd /k "echo Installing uv package manager... && powershell -ExecutionPolicy Bypass -Command ""try { irm https://astral.sh/uv/install.ps1 | iex; Write-Host 'uv installed successfully!' } catch { Write-Host 'Failed to install uv:' $_.Exception.Message; Write-Host 'Install manually from https://docs.astral.sh/uv/' }"" && echo Installation complete. Press any key to continue... && pause && exit"
    echo Waiting for uv installation to complete...
    echo Please wait for the uv installation window to finish, then press any key here.
    pause
    
    for /f "tokens=*" %%i in ('where uv 2^>nul') do set "uv_path=%%i"
    if not defined uv_path (
        set "PATH=%USERPROFILE%\.local\bin;%PATH%"
    )
) else (
    echo uv already installed.
)

echo.
echo Step 2: Installing Python 3.12 via uv...

uv python find 3.12 >nul 2>&1
if %errorLevel% neq 0 (
    echo Python 3.12 not found. Installing via uv in new terminal...
    start "Installing Python 3.12" cmd /k "uv python install 3.12 && echo Python 3.12 installation complete. Press any key to continue... && pause && exit"
    echo Waiting for Python 3.12 installation to complete...
    echo Please wait for the Python installation window to finish, then press any key here.
    pause
) else (
    echo Python 3.12 already installed.
)

echo.
echo Step 3: Setting up virtual environment and dependencies...
if not exist ".venv" (
    echo Creating virtual environment with Python 3.12...
    uv venv --python 3.12 .venv
    if not exist ".venv\Scripts\python.exe" (
        echo ERROR: Virtual environment creation failed.
        pause
        exit /b 1
    )
) else (
    echo Virtual environment exists.
)
uv sync --extra dev

echo.
echo Step 4: Checking WireGuard...
.venv\Scripts\python.exe scripts\install_wireguard.py

echo.
echo Step 5: Running setup checks...
.venv\Scripts\python.exe scripts\setup_project.py

echo.
echo Step 6: Starting LANrage...
echo Starting LANrage in new terminal window...
start "LANrage - Gaming VPN" cmd /k "echo Starting LANrage... && echo. && .venv\Scripts\python.exe lanrage.py"

echo.
echo ========================================
echo Installation and startup complete!
echo ========================================
echo.
echo LANrage is now running in a separate terminal window.
echo You can access the web interface at: http://localhost:8666
echo.
echo This window can be closed safely.
echo Press any key to exit...
pause
exit /b 0