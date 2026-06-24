#!/usr/bin/env python3
"""
LANrage WireGuard installer - cross-platform (Windows & Linux)
Downloads and installs WireGuard if not already present
"""

import os
import platform
import struct
import subprocess
import sys
import tempfile
import urllib.request


WINDOWS_MSI_BASE = "https://download.wireguard.com/windows-client"
WIREGUARD_PATHS = [
    "C:\\Program Files\\WireGuard\\wireguard.exe",
    "C:\\Program Files (x86)\\WireGuard\\wireguard.exe",
    os.path.expanduser("~\\AppData\\Local\\Programs\\WireGuard\\wireguard.exe"),
]
MARKER_FILE = ".wireguard_installed"


def _detect_windows_arch() -> str:
    machine = struct.calcsize("P") * 8
    proc_arch = os.environ.get("PROCESSOR_ARCHITECTURE", "").lower()
    if proc_arch == "arm64":
        return "arm64"
    return "amd64" if machine == 64 else "x86"


def _add_to_path(wg_exe: str):
    wg_dir = os.path.dirname(wg_exe)
    current_path = os.environ.get("PATH", "")
    if wg_dir not in current_path:
        os.environ["PATH"] = wg_dir + os.pathsep + current_path


def _write_marker(wg_exe: str):
    try:
        with open(MARKER_FILE, "w") as f:
            f.write(wg_exe + "\n")
    except Exception:
        pass


def _check_marker() -> str | None:
    try:
        with open(MARKER_FILE) as f:
            path = f.read().strip()
            if os.path.exists(path):
                return path
    except Exception:
        pass
    return None


def is_wireguard_installed() -> bool:
    system = platform.system()
    try:
        if system == "Windows":
            result = subprocess.run(
                ["where", "wireguard"], capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                return True
            for path in WIREGUARD_PATHS:
                if os.path.exists(path):
                    _add_to_path(path)
                    return True
            marker_path = _check_marker()
            if marker_path:
                _add_to_path(marker_path)
                return True
            return False
        else:
            result = subprocess.run(
                ["which", "wg"], capture_output=True, text=True, timeout=10
            )
            return result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


def install_windows() -> bool:
    import ctypes
    try:
        if not ctypes.windll.shell32.IsUserAnAdmin():
            print("Administrator privileges required to install WireGuard")
            print("Run this script from an Administrator Command Prompt")
            print("Or use one of the scripts in scripts/windows/")
            return False
    except Exception:
        pass

    arch = _detect_windows_arch()
    msi_name = f"wireguard-{arch}-1.1.msi"
    msi_url = f"{WINDOWS_MSI_BASE}/{msi_name}"
    print(f"Downloading {msi_name}...")
    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            msi_path = os.path.join(tmpdir, msi_name)
            urllib.request.urlretrieve(msi_url, msi_path)
            print("Download complete")

            print("Installing WireGuard...")
            result = subprocess.run(
                ["msiexec", "/i", msi_path, "/qn", "/norestart"],
                capture_output=True,
                text=True,
                timeout=120,
            )

            if result.returncode == 0:
                print("WireGuard installed successfully")
                for path in WIREGUARD_PATHS:
                    if os.path.exists(path):
                        _add_to_path(path)
                        _write_marker(path)
                        return True
                prog_files = os.environ.get("ProgramFiles", "C:\\Program Files")
                fallback = os.path.join(prog_files, "WireGuard", "wireguard.exe")
                if os.path.exists(fallback):
                    _add_to_path(fallback)
                    _write_marker(fallback)
                    return True
                _write_marker(prog_files + "\\WireGuard\\wireguard.exe")
                return True
            else:
                print(f"Installation failed (code: {result.returncode})")
                if result.stderr:
                    print(f"  {result.stderr}")
                return False
    except Exception as e:
        print(f"Installation failed: {e}")
        return False


def install_linux() -> bool:
    managers = [
        ("apt-get", ["sudo", "apt-get", "install", "-y", "wireguard"]),
        ("dnf", ["sudo", "dnf", "install", "-y", "wireguard-tools"]),
        ("yum", ["sudo", "yum", "install", "-y", "wireguard-tools"]),
        ("pacman", ["sudo", "pacman", "-S", "--noconfirm", "wireguard-tools"]),
        ("zypper", ["sudo", "zypper", "install", "-y", "wireguard-tools"]),
    ]
    for pm, cmd in managers:
        try:
            subprocess.run(["which", pm], capture_output=True, check=True)
            print(f"Installing WireGuard via {pm}...")
            subprocess.run(cmd, timeout=120, check=True)
            print("WireGuard installed successfully")
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            continue
    print("Could not detect package manager")
    return False


def main():
    print("LANrage - WireGuard Installer")
    print("=" * 60)

    if is_wireguard_installed():
        print("WireGuard is already installed")
        return

    system = platform.system()
    print(f"Platform: {system}")

    if system == "Windows":
        success = install_windows()
    elif system == "Linux":
        success = install_linux()
    else:
        print(f"Unsupported platform: {system}")
        success = False

    if success:
        print("WireGuard installation complete")
    else:
        print("WireGuard installation failed")
        print("Install manually from: https://www.wireguard.com/install/")
        sys.exit(1)


if __name__ == "__main__":
    main()
