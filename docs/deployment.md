# Deployment Guide

## Deploying to a New Host with nixos-anywhere

To deploy NixOS to a remote computer using nixos-anywhere:

```bash
nix run github:nix-community/nixos-anywhere \
  -- --disko-mode disko \
  --flake ~/Documents/nixos-anywhere/nixos#hab \
  --generate-hardware-config nixos-generate-config \
  ./hardware-configuration.nix \
  root@10.0.0.6
```

### After Deployment

Once deployed, copy the configuration files to the remote machine:

```bash
cd ~/Documents/nixos-anywhere/nixos
scp -r ./ root@10.0.0.6:/etc/nixos

# Create SSH directories if they don't exist
mkdir /etc/nixos/ssh
mkdir /etc/nixos/ssh/authorized_keys

# Copy secrets (if using nix-sops)
scp -r ./secrets/ root@10.0.0.6:/etc/nixos/ssh/authorized_keys/
```

## Remote Rebuilds

To rebuild without overwriting everything on the remote system:

```bash
nixos-rebuild switch \
  --flake .#hab \
  --target-host root@10.0.0.65
```

### Other Useful Commands

```bash
# Test build (doesn't activate)
nixos-rebuild test --flake .#hab

# Switch to a specific generation
nixos-rebuild switch --flake .#hab --rollback

# Show current configuration
nixos-rebuild list-generations --flake .#hab
```

## Adding New Hosts

1. Deploy base system using nixos-anywhere as shown above
2. Copy hardware configuration from the new host:
   ```bash
   ssh root@<new-host-ip> 'nixos-generate-config --show-hardware-config' \
     > hosts/<hostname>/hardware-configuration.nix
   ```
3. Update `flake.nix` with the new host configuration
4. Test: `nix flake check --flake .`
5. Deploy: `nixos-rebuild switch --flake .#<hostname>`