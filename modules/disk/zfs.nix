{ lib, pkgs, ... }:

{
  
  imports = [];

  # Boot configuration for ZFS
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # ZFS packages
  environment.systemPackages = with pkgs; [
    zfs
  ];

  # Additional ZFS-related settings can be added here
}