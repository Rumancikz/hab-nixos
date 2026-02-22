{ config, pkgs, ... }:

{
  # Enable NetworkManager for network management (better for laptops)
  networking.networkmanager.enable = true;

  # NetworkManager provides the nmcli and nmtui tools
  environment.systemPackages = [
    pkgs.networkmanagerapplet
    pkgs.networkmanager
  ];

  # Enable Wi-Fi support
  hardware.bluetooth.enable = true;
  hardware wireless.enable = true;
}