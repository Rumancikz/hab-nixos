# Host-specific secrets configuration for hab-lab
# This file imports the sops module and configures secrets for this host
{ config, lib, ... }:

{
  imports = [
    ../../modules/secrets/sops.nix
  ];

  # Enable sops-nix secrets management
  homelab.secrets.enable = true;

  # User password secrets
  sops.secrets."users/root/hashed-password" = {
    sopsFile = ../../secrets/users.yaml;
    key = "users/root/hashed-password";
    neededForUsers = true;  # Required for user passwords
  };

  sops.secrets."users/hab-lab/hashed-password" = {
    sopsFile = ../../secrets/users.yaml;
    key = "users/hab-lab/hashed-password";
    neededForUsers = true;
  };

  # Configure users to use sops-managed passwords
  # Note: When using hashedPasswordFile, initialHashedPassword should not be set
  users.users = {
    root = {
      hashedPasswordFile = config.sops.secrets."users/root/hashed-password".path;
      # Remove initialHashedPassword when using sops
      # initialHashedPassword is mutually exclusive with hashedPasswordFile
    };
    hab-lab = {
      hashedPasswordFile = config.sops.secrets."users/hab-lab/hashed-password".path;
    };
  };
}