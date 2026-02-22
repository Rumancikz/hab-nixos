{ config, pkgs, ... }:

{
  # Enable Wi-Fi support via NetworkManager
  networking.networkmanager.enable = true;

  # NetworkManager provides the nmcli and nmtui tools
  environment.systemPackages = [
    pkgs.networkmanagerapplet
    pkgs.networkmanager
  ];

  # Enable wireless hardware support
  hardware.wireless.enable = true;
}