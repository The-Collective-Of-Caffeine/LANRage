@echo off
setlocal enabledelayedexpansion

echo ========================================
echo LANrage Complete Installation Script
echo ========================================
echo.

REM Uses standalone uv installer — no Chocolatey or pip needed

REM ---------- Step 1: Install uv ----------
echo Step 1: Installing uv package manager...
where uv >nul 2>&1
if %errorLevel% neq 0 (
    echo uv not found. Installing in new terminal...
    start "Install uv" cmd /k "powershell -ExecutionPolicy Bypass -Command ""try { irm https://astral.sh/uv/install.ps1 | iex; Write-Host 'uv installed successfully!' } catch { Write-Host 'Failed:' $_.Exception.Message; pause; exit 1 }"" && echo Press any key to continue... && pause && exit"
    echo Waiting for uv installation to complete...
    echo Please wait for the installation window to finish, then press any key here.
    pause
    for /f "tokens=*" %%i in ('"%USERPROFILE%\.local\bin\uv.exe" version 2^>nul') do set "PATH=%USERPROFILE%\.local\bin;%PATH%"
) else (
    echo uv already installed.
)

echo.

REM ---------- Step 2: Ensure Python 3.12 ----------
echo Step 2: Checking Python 3.12...
python --version 2>nul | findstr "3.12" >nul
if %errorLevel% neq 0 (
    echo Python 3.12 not found. Installing via uv...
    start "Install Python 3.12" cmd /k "uv python install 3.12 && echo Python 3.12 installed! && echo Press any key to continue... && pause && exit"
    echo Waiting for Python installation to complete...
    echo Please wait for the installation window to finish, then press any key here.
    pause
) else (
    echo Python 3.12 already available.
)

echo.

REM ---------- Step 3: Virtual environment + dependencies ----------
echo Step 3: Setting up virtual environment and dependencies...
if not exist ".venv" (
    echo Creating virtual environment and installing dependencies...
    start "LANrage Setup" cmd /k "uv venv --python 3.12 && uv sync && echo. && echo Dependencies installed successfully. && echo Press any key to continue... && pause && exit"
    echo Waiting for environment setup to complete...
    echo Please wait for the setup window to finish, then press any key here.
    pause
) else (
    echo Virtual environment already exists. Updating dependencies...
    start "LANrage Update" cmd /k "uv sync && echo. && echo Dependencies updated successfully. && echo Press any key to continue... && pause && exit"
    echo Waiting for dependency update to complete...
    echo Please wait for the update window to finish, then press any key here.
    pause
)

echo.

REM ---------- Step 4: Initialize database ----------
echo Step 4: Running initial setup...
if not exist ".env" (
    echo Running initial setup in new terminal...
    start "LANrage Initial Setup" cmd /k "echo Running LANrage setup... && .venv\Scripts\python.exe scripts\setup_project.py && echo Setup completed successfully. && echo Press any key to continue... && pause && exit"
    echo Waiting for setup to complete...
    echo Please wait for the setup window to finish, then press any key here.
    pause
) else (
    echo Setup already completed (.env file exists).
)

echo.

REM ---------- Step 5: Start LANrage ----------
echo Step 5: Starting LANrage...
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
