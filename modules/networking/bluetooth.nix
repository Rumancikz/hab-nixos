{ config, pkgs, ... }:

{
  # Enable Bluetooth support
  hardware.bluetooth.enable = true;

  # Bluetooth tools and utilities
  environment.systemPackages = [
    pkgs.bluez
    pkgs.bluez-tools
  ];
}