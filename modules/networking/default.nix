# Networking module aggregator
{ lib, pkgs, ... }:

{
  imports = [
    ./bluetooth.nix
    ./wifi.nix
    ./tailscale.nix
  ];
}