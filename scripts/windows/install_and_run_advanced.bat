@echo off
setlocal enabledelayedexpansion

REM Advanced LANrage Installation Script with Error Handling
REM Uses standalone uv installer — no Chocolatey or pip needed

echo ========================================
echo LANrage Advanced Installation Script
echo ========================================
echo.

REM Function to check if command exists
:check_command
where %1 >nul 2>&1
exit /b %errorLevel%

REM Function to wait for user confirmation
:wait_for_user
echo Press any key when the installation window has completed...
pause >nul
goto :eof

echo.
echo ========================================
echo STEP 1: UV INSTALLATION
echo ========================================

call :check_command uv
if %errorLevel% neq 0 (
    echo uv not found. Installing standalone via PowerShell...
    echo.
    echo Opening uv installation in new window...
    start "Install uv" cmd /c "echo Installing uv package manager... && echo. && powershell -ExecutionPolicy Bypass -Command ""try { irm https://astral.sh/uv/install.ps1 | iex; Write-Host 'uv installed successfully!' } catch { Write-Host 'Failed:' $_.Exception.Message; pause; exit 1 }"" && echo. && echo Installation window will close in 10 seconds... && timeout /t 10"

    call :wait_for_user

    REM Refresh PATH to pick up uv
    for /f "tokens=*" %%i in ('"%USERPROFILE%\.local\bin\uv.exe" version 2^>nul') do set "PATH=%USERPROFILE%\.local\bin;%PATH%"

    call :check_command uv
    if %errorLevel% neq 0 (
        echo ERROR: Could not install uv package manager.
        echo Please install manually from https://docs.astral.sh/uv/
        pause
        exit /b 1
    )
    echo uv installed successfully!
) else (
    echo uv already installed.
)

echo.
echo ========================================
echo STEP 2: PYTHON 3.12 INSTALLATION
echo ========================================

REM Check for Python 3.12 — install via uv if missing
python --version 2>nul | findstr "3.12" >nul
if %errorLevel% neq 0 (
    echo Python 3.12 not found. Installing via uv...
    echo.
    echo Opening Python installation in new window...
    start "Install Python 3.12" cmd /c "echo Installing Python 3.12 via uv... && echo. && uv python install 3.12 && echo. && echo Python 3.12 installed! && echo Window will close in 10 seconds... && timeout /t 10"

    call :wait_for_user

    REM Verify installation
    python --version 2>nul | findstr "3.12" >nul
    if %errorLevel% neq 0 (
        echo WARNING: Python 3.12 installation via uv may have failed.
        echo You can install Python 3.12 manually from python.org or run: uv python install 3.12
        echo Continue anyway? (Y/N)
        set /p continue=
        if /i "!continue!" neq "Y" exit /b 1
    ) else (
        echo Python 3.12 installed successfully!
    )
) else (
    echo Python 3.12 already available.
)

echo.
echo ========================================
echo STEP 3: VIRTUAL ENVIRONMENT SETUP
echo ========================================

if not exist ".venv" (
    echo Creating virtual environment and installing dependencies...
    echo.
    echo Opening environment setup in new window...
    start "LANrage Setup" cmd /c "echo Creating Python 3.12 virtual environment... && echo. && uv venv --python 3.12 && echo Virtual environment created! && echo. && echo Installing project dependencies... && uv sync && echo. && echo All dependencies installed successfully! && echo. && echo Setup window will close in 15 seconds... && timeout /t 15"

    call :wait_for_user

    if not exist ".venv\Scripts\python.exe" (
        echo ERROR: Virtual environment creation failed.
        pause
        exit /b 1
    )
    echo Virtual environment created successfully!
) else (
    echo Virtual environment already exists. Updating dependencies...
    echo.
    echo Opening dependency update in new window...
    start "Dependency Update" cmd /c "echo Updating project dependencies... && echo. && uv sync && echo. && echo Dependencies updated successfully! && echo. && echo Update window will close in 10 seconds... && timeout /t 10"

    call :wait_for_user
)

echo.
echo ========================================
echo STEP 4: LANRAGE INITIAL SETUP
echo ========================================

if not exist ".env" (
    echo Running LANrage initial setup...
    echo.
    echo Opening setup in new window...
    start "LANrage Setup" cmd /c "echo Running LANrage initial configuration... && echo. && .venv\Scripts\python.exe scripts\setup_project.py && echo. && echo LANrage setup completed successfully! && echo. && echo Setup window will close in 10 seconds... && timeout /t 10"

    call :wait_for_user

    if not exist ".env" (
        echo WARNING: Setup may not have completed successfully.
        echo Continue anyway? (Y/N)
        set /p continue=
        if /i "!continue!" neq "Y" exit /b 1
    )
    echo LANrage setup completed!
) else (
    echo LANrage already configured (.env file exists).
)

echo.
echo ========================================
echo STEP 5: STARTING LANRAGE
echo ========================================

echo Starting LANrage in dedicated terminal...
echo.
start "LANrage - Gaming VPN Server" cmd /k "title LANrage - Gaming VPN && echo. && echo ======================================== && echo           LANrage Gaming VPN && echo ======================================== && echo. && echo Starting LANrage server... && echo. && .venv\Scripts\python.exe lanrage.py"

echo.
echo ========================================
echo INSTALLATION COMPLETE!
echo ========================================
echo.
echo LANrage is now running in a separate terminal window.
echo.
echo Web Interface: http://localhost:8666
echo.
echo If you encounter any issues:
echo 1. Check the LANrage terminal window for error messages
echo 2. Check that WireGuard is installed on your system
echo 3. Review the troubleshooting guide in docs/TROUBLESHOOTING.md
echo.
echo This installation window can now be closed.
echo.
pause
exit /b 0
