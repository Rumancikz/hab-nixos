# Services module aggregator
{
  imports = [
    ./nextcloud.nix
    ./firefly-iii.nix
    ./immich.nix
    ./mealie.nix
  ];
}