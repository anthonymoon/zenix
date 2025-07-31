# Zenix Installation Guide

## ⚠️ WARNING: Default device is now /dev/nvme0n1
The system defaults to `/dev/nvme0n1` to avoid accidentally wiping USB drives.

## Installation Commands

### Method 1: Using disko directly with device override
```bash
# For NVMe drives (default)
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  --flake github:anthonymoon/zenix#default

# For other devices (e.g., /dev/sda)
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  --flake github:anthonymoon/zenix#default \
  --arg disk '{ device = "/dev/sda"; }'
```

### Method 2: Manual override before running
```bash
# Set your device first
export TARGET_DISK="/dev/nvme0n1"  # Change this to your actual disk!

# Then run disko
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  --flake github:anthonymoon/zenix#default \
  --arg disk "{ device = \"$TARGET_DISK\"; }"
```

## Install NixOS
After formatting, install NixOS:
```bash
sudo nixos-install --flake github:anthonymoon/zenix#workstation.kde.stable --no-channel-copy
```

## Available Configurations
- `workstation.kde.stable` - KDE desktop on stable channel
- `laptop.hyprland.gaming.chaotic` - Hyprland with gaming support
- `server.headless.hardened` - Hardened headless server
- `desktop.gnome.stable` - GNOME desktop

## Disk Layout (ZFS)
- **Boot**: 1GB FAT32 partition for UEFI
- **ZFS Pool**: Rest of disk with datasets:
  - `zroot/root` - System root (/)
  - `zroot/nix` - Nix store (/nix)
  - `zroot/home` - User home directories (/home)
  - `zroot/reserved` - 1GB reserved space

## Recovery
If you accidentally wiped the wrong disk:
1. Your USB installer should still work if you reboot
2. You may need to recreate the USB with Ventoy or dd
3. The actual NixOS ISO data might still be intact in the loop device