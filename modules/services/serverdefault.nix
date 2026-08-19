# Services module aggregator
{ lib, pkgs, ... }:

{
  imports = [
    # ./firefly-iii.nix
    ./borgbackup.nix
    ./immich.nix
    ./mealie.nix
    ./paperless-ngx.nix
    ./nextcloud.nix
    ./dashboard.nix
  ];
}