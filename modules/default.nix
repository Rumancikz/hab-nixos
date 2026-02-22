# Shared modules for all hosts - dendritic pattern aggregator
{
  imports = [
    ./networking/default.nix
    ./services/default.nix
    ./disk/default.nix
    ./desktop/default.nix
    ./audio/default.nix
    ./input/default.nix
    ./users/zman.nix
    ./applications/default.nix
    ./caddy.nix
  ];

  # Additional shared configurations can be added here
}