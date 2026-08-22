# HAB NixOS Configuration - Dendritic Pattern

A NixOS homeserver configuration using flake-parts and the dendritic pattern for scalable infrastructure management.

## Overview

This repository uses a hierarchical "dendritic" structure where:
- **Root** (`flake.nix`) - Orchestrates the tree
- **Branches** (`modules/`) - Shared, reusable modules
- **Leaves** (`hosts/`) - Per-host configurations

## Directory Structure

```
hab-nixos/
├── flake.nix                    # Main flake with flake-parts
├── flake.lock                   # Lock file (auto-generated)
├── README.md                    # This file
│
├── hosts/                       # Per-host configurations (leaf nodes)
│   └── hab/                     # Current host configuration
│       ├── configuration.nix    # Host-specific config
│       └── hardware-configuration.nix  # Hardware settings
│
└── modules/                     # Shared, reusable modules (branch nodes)
    ├── default.nix              # Module aggregator
    ├── caddy.nix                # Caddy web server module
    ├── disk/                    # Disk configuration
    │   ├── default.nix          # Disk wrapper
    │   └── disk-config.nix      # Disko + ZFS config
    ├── networking/              # Network settings
    │   ├── default.nix          # Networking aggregator
    │   └── tailscale.nix        # Tailscale VPN module
    └── services/                # Service modules
        ├── default.nix          # Services aggregator
        ├── nextcloud.nix        # Nextcloud module
        ├── firefly-iii.nix      # Firefly III module
        ├── immich.nix           # Immich module
        └── mealie.nix           # Mealie module
```

## Key Benefits

- **Scalable**: Add new hosts without touching shared configs
- **Reusable**: Modules can be shared across multiple hosts
- **Clear separation**: Network, disk, services, security are organized
- **Modern best practices**: Uses flake-parts for better organization

## Usage

### Build and switch to the configuration

```bash
nixos-rebuild switch --flake .#hab
```

### Test the configuration (without switching)

```bash
nixos-rebuild test --flake .#hab
```

### Check for errors without building

```bash
nix flake check --flake .
```

## Adding a New Host

1. Create host directory: `mkdir hosts/<hostname>`

2. Copy hardware config or create new:
   ```bash
   cp hosts/hab/hardware-configuration.nix hosts/<hostname>/
   ```

3. Create `hosts/<hostname>/configuration.nix`:
   ```nix
   { config, pkgs, ... }:

   {
     imports = [
       ../modules/disk/default.nix
       ../modules/networking/default.nix
       ../modules/services/default.nix
     ];

     networking.hostName = "<hostname>";
     # Additional host-specific settings...
   }
   ```

4. Add to `flake.nix`:
   ```nix
   perSystem.<hostname> = { pkgs, ... }: {
     nixosConfigurations = {
       <hostname> = nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         modules = [
           disko.nixosModules.disko
           ./hosts/<hostname>/configuration.nix
         ];
       };
     };
   };
   ```

5. Test: `nixos-rebuild switch --flake .#<hostname>`

## Current Services (hab-lab-1)

All `*.zachru.com` URLs resolve to the Tailscale IP `100.104.22.20` (GoDaddy A records `@` and `*`) — an RFC 6598 CGNAT address, so the services are **reachable only from inside the tailnet**. Caddy terminates HTTPS with Let's Encrypt certs (issued via `security.acme`/lego using the GoDaddy DNS-01 challenge), so any tailnet device gets a valid green lock.

| Service | URL | Backend | Description |
|---------|-----|---------|-------------|
| Dashboard | https://zachru.com · https://hab-lab-1.zachru.com | :8082 | Homepage front door (Caddy) |
| Mealie | https://mealie.zachru.com | :9000 (loopback-only) | Recipe manager |
| Open WebUI | https://ai.zachru.com | habai:3000 (tailnet) | Private local LLM chat |
| Paperless-ngx | https://paperless.zachru.com | :3343 | Document management |
| Nextcloud | http://100.104.22.20:8008 | :8008 | File sync (direct — not yet behind Caddy) |
| SSH | hab-lab@10.0.0.6:22 | :22 | Key-auth only |

Not currently enabled: Firefly III, Immich.

## Documentation

Additional documentation is available in the [`docs/`](docs/) directory:

| Document | Description |
|----------|-------------|
| [networking.md](docs/networking.md) | Network topology and IP address plan |
| [deployment.md](docs/deployment.md) | Deployment instructions for new hosts |
| [troubleshooting.md](docs/troubleshooting.md) | ZFS recovery and system troubleshooting |

## Requirements

- Nix with flakes enabled
- Disko for disk configuration (ZFS support)

## License

MIT