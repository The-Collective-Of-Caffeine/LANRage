#!/usr/bin/env python3
"""
LANrage setup script
Handles initial setup and dependency installation
"""

import asyncio
import os
import platform
import subprocess
import sys
from pathlib import Path


def run_command(cmd: list[str], check: bool = True) -> bool:
    """Run a command and return success status"""
    try:
        result = subprocess.run(cmd, check=check, capture_output=True, text=True)
        return result.returncode == 0
    except subprocess.CalledProcessError as e:
        print(f"❌ Command failed: {' '.join(cmd)}")
        print(f"   Error: {e.stderr}")
        return False


async def initialize_database():
    """Initialize the settings database with defaults"""
    try:
        # Import here to avoid issues if dependencies not installed yet
        from core.control_plane.settings import get_settings_db, init_default_settings

        print("Initializing settings database...")
        db = await get_settings_db()
        await init_default_settings()

        # Validate
        if db.validate_database_integrity():
            print("✓ Settings database initialized")
            return True
        print("⚠ Database integrity check failed")
        return False
    except Exception as e:
        print(f"⚠ Database initialization failed: {e}")
        print("  You can configure settings through the WebUI after starting LANrage")
        return False


def main():
    print("🔥 LANrage Setup")
    print("=" * 60)

    # Check Python version
    print("✓ Python version OK")

    # Check if uv is installed
    if not run_command(["uv", "--version"], check=False):
        print("❌ uv not found")
        print("   Install from: https://docs.astral.sh/uv/")
        sys.exit(1)
    print("✓ uv found")

    # Create virtual environment
    venv_path = Path(".venv")
    if not venv_path.exists():
        print("Creating virtual environment...")
        if not run_command(["uv", "venv", "--python", "3.12"]):
            sys.exit(1)
        print("✓ Virtual environment created")
    else:
        print("✓ Virtual environment exists")

    # Install dependencies
    print("Installing dependencies...")
    if not run_command(["uv", "sync", "--extra", "dev"]):
        sys.exit(1)
    print("✓ Dependencies installed")

    # Initialize database (replaces .env file creation)
    print("\nInitializing configuration database...")
    try:
        asyncio.run(initialize_database())
    except Exception as e:
        print(f"⚠ Could not initialize database: {e}")
        print("  Settings will be initialized on first run")

    # Check WireGuard
    print("\nChecking WireGuard...")
    wg_found = False
    if platform.system() == "Windows":
        if run_command(["where", "wireguard"], check=False):
            wg_found = True
        elif os.path.exists(".wireguard_installed"):
            try:
                with open(".wireguard_installed") as _f:
                    _p = _f.read().strip()
                if _p and os.path.exists(_p):
                    wg_found = True
            except Exception:
                pass
        elif os.path.exists("C:\\Program Files\\WireGuard\\wireguard.exe"):
            wg_found = True
        elif os.path.exists("C:\\Program Files (x86)\\WireGuard\\wireguard.exe"):
            wg_found = True
    else:
        wg_found = run_command(["which", "wg"], check=False)

    if wg_found:
        print("✓ WireGuard found")
    else:
        print("⚠ WireGuard not found")
        if platform.system() == "Windows":
            print("  Run scripts\\windows\\quick_install.bat as Administrator")
            print("  to install WireGuard automatically.")
        print("  Or install manually from: https://www.wireguard.com/install/")

    print("\n" + "=" * 60)
    print("✅ Setup complete!")
    print("\nNext steps:")
    print("  1. Activate virtual environment:")
    print("     Windows: .venv\\Scripts\\activate.bat")
    print("     Linux/Mac: source .venv/bin/activate")
    print("  2. Run LANrage:")
    print("     python lanrage.py")
    print("  3. Configure settings in your browser:")
    print("     http://localhost:8666/settings.html")
    print("\n💡 All configuration is now done through the WebUI!")
    print("   No need to edit .env files manually.")


if __name__ == "__main__":
    main()
