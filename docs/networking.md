# Network Topology

## IP Address Plan

| Device | IP Address | Description |
|--------|------------|-------------|
| Router | 10.0.0.1 | Current network router |
| hab-atlas | 10.0.0.2 | Future NixOS server (planned) |
| pikvm 1 | 10.0.0.140 | PiKVM for remote management |
| hab-lab-1 | 10.0.0.6 | Current NixOS homeserver |

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
```

## Tailscale Access

- **hab-lab-1 Tailscale IP**: `100.104.22.20` (MagicDNS name: `hab-lab-1`)
- Services are exposed **only** over Tailscale — the tailnet IP is CGNAT (RFC 6598) and unroutable from the public internet.

### DNS (GoDaddy)

| Type | Name | Value | Purpose |
|------|------|-------|---------|
| A | `*` | `100.104.22.20` | all subdomains (hab-lab-1, mealie, ai, paperless, …) |
| A | `@` | `100.104.22.20` | the bare `zachru.com` |

HTTPS certificates: Let's Encrypt via `security.acme` (lego, GoDaddy DNS-01 challenge), loaded by Caddy (see `modules/caddy.nix`). Renewal is automatic; certs cover `zachru.com` + `*.zachru.com`.

### Service URLs

| Service | URL |
|---------|-----|
| Dashboard | https://zachru.com · https://hab-lab-1.zachru.com |
| Mealie | https://mealie.zachru.com |
| Open WebUI | https://ai.zachru.com |
| Paperless-ngx | https://paperless.zachru.com |
| Nextcloud | http://100.104.22.20:8008 (LAN: http://10.0.0.6:8008) |