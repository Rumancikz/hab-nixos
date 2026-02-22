{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ self, nixpkgs, disko, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
  
      perSystem = { pkgs, ... }: {
        nixosConfigurations = {
          hab = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/hab/configuration.nix
            ];
          };
        };
      };
  
      # Example: Future hosts can be added here
      # perSystem.hab-atlas = { pkgs, ... }: {
      #   nixosConfigurations = {
      #     hab-atlas = pkgs.nixos {
      #       configuration = {
      #         imports = [
      #           ./hosts/hab-atlas/configuration.nix
      #           disko.nixosModules.disko
      #         ];
      #       };
      #     };
      #   };
      # };
  
      # perSystem.pikvm = { pkgs, ... }: {
      #   nixosConfigurations = {
      #     pikvm = pkgs.nixos {
      #       configuration = {
      #         imports = [
      #           ./hosts/pikvm/configuration.nix
      #         ];
      #       };
      #     };
      #   };
      # };
    };
}
