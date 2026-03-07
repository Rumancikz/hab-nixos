# Services module aggregator
{ lib, pkgs, ... }:

{
  imports = [
    ./nextcloud.nix
    ./firefly-iii.nix
    ./immich.nix
    ./mealie.nix
  ];
}