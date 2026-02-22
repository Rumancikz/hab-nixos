# Networking module aggregator
{
  imports = [
    ./bluetooth.nix
    ./wifi.nix
    ./tailscale.nix
  ];
}