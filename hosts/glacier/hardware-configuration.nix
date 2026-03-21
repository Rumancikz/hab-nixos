# PLACEHOLDER: Replace this file with the output of:
#   nixos-generate-config --show-hardware-config
# Run on the glacier machine after booting a NixOS installer.
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  # TODO: Fill in from nixos-generate-config output
}
