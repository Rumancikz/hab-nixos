# Host-specific secrets configuration for warframe
# This file imports the sops module and configures secrets for this host
{ config, lib, ... }:

{
  imports = [
    ../../modules/secrets/sops.nix
  ];

  # Enable sops-nix secrets management
  homelab.secrets.enable = true;

  # User password secrets
  sops.secrets."users/zman/hashed-password" = {
    sopsFile = ../../secrets/users.yaml;
    key = "users/zman/hashed-password";
    neededForUsers = true;  # Required for user passwords
  };

  # Configure users to use sops-managed passwords
  # Note: When using hashedPasswordFile, initialHashedPassword should not be set
  users.users.zman = {
    hashedPasswordFile = config.sops.secrets."users/zman/hashed-password".path;
  };
}