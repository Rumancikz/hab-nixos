# Sops-nix configuration module
# This module provides common sops configuration and helper functions
# for managing secrets across your NixOS hosts.
#
# Usage:
#   1. Import this module in your host configuration
#   2. Define secrets in secrets/*.yaml files
#   3. Reference secrets using config.sops.secrets."path/to/secret"
{ config, lib, pkgs, ... }:

let
  cfg = config.homelab.secrets;
in
{
  options.homelab.secrets = {
    enable = lib.mkEnableOption {
      description = "Enable sops-nix secrets management";
      default = true;
    };

    # Default age key file location
    ageKeyFile = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/sops-nix/key.txt";
      description = "Path to the age private key file";
    };

    # Default secrets directory
    secretsDir = lib.mkOption {
      type = lib.types.path;
      default = "/run/secrets";
      description = "Directory where decrypted secrets are placed";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure sops-nix defaults
    sops = {
      # Age key location on the target system
      age.keyFile = cfg.ageKeyFile;

      # Default secret permissions
      defaultSopsFile = lib.mkDefault null;  # Must be specified per secret or globally

      # Default owner/group for secrets
      defaultOwner = lib.mkDefault "root";
      defaultGroup = lib.mkDefault "root";
      defaultMode = lib.mkDefault "0400";
    };

    # Ensure the age key directory exists with correct permissions
    system.activationScripts.sops-key-dir = lib.mkIf (cfg.ageKeyFile == "/var/lib/sops-nix/key.txt") {
      text = ''
        mkdir -p /var/lib/sops-nix
        chmod 700 /var/lib/sops-nix
      '';
    };
  };
}