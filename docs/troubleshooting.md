# Troubleshooting Guide

## ZFS Recovery Commands

### Import a ZFS Pool from Another System

To access ZFS drives that are mounted on another Linux system:

```bash
# Import pool in read-only mode first (safe)
zpool import ocean -d /dev -o readonly=on -f -R /ocean

# Check mountpoints
zfs get mountpoint ocean/tank

# Mount the filesystem
mount -t zfs ocean/tank /ocean

# When done, export the pool cleanly
zpool export ocean
```

### Common ZFS Operations

```bash
# List all pools
zpool list

# Check pool status
zpool status

# Check filesystem mountpoints
zfs get mountpoint

# Force import (use with caution)
zpool import -f <poolname>
```

## System Recovery

### Boot into Previous Generation

If the new configuration causes issues:

```bash
# List available generations
nixos-rebuild list-generations

# Switch to previous generation
nixos-rebuild switch --rollback

# Or switch to a specific generation
nixos-rebuild switch --profile /nix/var/nix/profiles/system-<generation>-link
```

### Emergency Shell

If the system fails to boot:

1. At GRUB menu, press `e` to edit boot options
2. Add `boot.initrd.postMountCommands = "mount -o remount,rw /dev/disk/by-label/NIXOS_LABEL /mnt; cd /mnt; nix-store --verify --check-contents"`;
3. Boot with `Ctrl+X`

## Service Management

### Restart a Specific Service

```bash
# Using systemctl
sudo systemctl restart <service-name>

# Example: Restart Nextcloud
sudo systemctl restart php-fpm nextcloud
```

### View Service Logs

```bash
# All logs
journalctl -xe

# Service-specific logs
journalctl -u <service-name>

# Follow logs in real-time
journalctl -fu <service-name>
```

## Debugging NixOS Configurations

### Check Configuration Syntax

```bash
# Validate the configuration
nixos-install --dry-run

# Evaluate flake without building
nix flake check --flake .

# Show what would be built
nix-instantiate --eval flake.nix --attr systems.x86_64-linux.config
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Configuration not found | Ensure `hosts/<hostname>/configuration.nix` exists and is imported in flake.nix |
| Module not found | Check that module paths are correct relative to host config |
| Nix store full | Run `nix-store --gc` to clean up unused packages |

## Hardware Information

### Generate Hardware Configuration

```bash
# On the target machine
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# Or save to /etc/nixos
sudo nixos-generate-config --file /etc/nixos/hardware-configuration.nix
```

### List Hardware

```bash
# CPU info
lscpu

# Disk info
lsblk -f

# Network interfaces
ip link show

# PCI devices
lspci