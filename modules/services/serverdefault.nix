# Services module aggregator
{ lib, pkgs, ... }:

{
  imports = [
    # ./firefly-iii.nix
    ./immich.nix
    ./mealie.nix
  ];
}