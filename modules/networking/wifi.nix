{ config, pkgs, ... }:

{
  # Enable Wi-Fi support via NetworkManager
  networking.networkmanager.enable = true;
}