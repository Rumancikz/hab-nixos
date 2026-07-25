{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Mealie v3.21.0 — nixpkgs has 3.16.0, we need AI provider features
    mealie = {
      url = "github:mealie-recipes/mealie/e22b8e7b734fb56d6f54a44526005104d3ac8f30";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, disko, ... }@inputs: {
    nixosConfigurations = {
      hab-lab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko
          ./hosts/hab-lab/configuration.nix
        ];
      };

      warframe = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/warframe/configuration.nix

          # home-manager.nixosModules.home-manager
          # {
          #   home-manager.useGlobalPkgs = true;
          #   home-manager.useUserPackages = true;
            
          #   home-manager.users.zman = import ./modules/users/zman/home.nix; 
          # }
        ];
      };

      glacier = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/glacier/configuration.nix
        ];
      };
    };
  };
}
