# Shared modules for all hosts
{
  # Import all shared service modules
  ./nextcloud.nix
  ./firefly-iii.nix
  ./immich.nix
  ./mealie.nix
  ./tailscale.nix
  ./caddy.nix

  # Additional shared configurations can be added here
}