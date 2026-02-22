# Shared modules for all hosts
{
  imports = [
    ./nextcloud.nix
    ./firefly-iii.nix
    ./immich.nix
    ./mealie.nix
    ./tailscale.nix
    ./caddy.nix
  ];

  # Additional shared configurations can be added here
}