{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    {
      nixpkgs,
      disko,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem = { config, self', pkgs, lib, ... }: {
        # Make nixos-install and other NixOS tools available
        _module.args.pkgs = import nixpkgs {
          system = "x86_64-linux";
        };
      };

      # Define NixOS configurations using flake-parts' nixosSystem helper
      nixosConfigurations = {
        hab-lab-1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/hab/configuration.nix
            disko.nixosModules.disko
            ./disk-config.nix
          ];
        };

        # Example: Future hosts can be added here
        # hab-atlas = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   modules = [
        #     ./hosts/hab-atlas/configuration.nix
        #     disko.nixosModules.disko
        #   ];
        # };

        # pikvm = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   modules = [
        #     ./hosts/pikvm/configuration.nix
        #   ];
        # };
      };
    };
}
