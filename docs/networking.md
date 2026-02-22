# Network Topology

## IP Address Plan

| Device | IP Address | Description |
|--------|------------|-------------|
| Router | 10.0.0.1 | Current network router |
| hab-atlas | 10.0.0.2 | Future NixOS server (planned) |
| pikvm 1 | 10.0.0.4 | PiKVM for remote management |
| hab-lab-1 | 10.0.0.65 | Current NixOS homeserver |

## Network Configuration

The current host (`hab-lab-1`) uses:
- **Hostname**: `hab-lab-1`
- **Domain**: `lab`
- **Network**: `10.0.0.0/24`

### Host-specific Settings

```nix
# In hosts/hab/configuration.nix
networking.hostName = "hab-lab-1";
networking.domain = "lab";

# Network interfaces
networking.interfaces.eno1.useDHCP = true;