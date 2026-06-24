@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0..\.."

if exist ".venv" (
    echo Removing virtual environment...
    rmdir /s /q ".venv"
    echo Done.
) else (
    echo No virtual environment found.
)

pause
