{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";
  # inputs.sops-nix.url = "github:Mic92/sops-nix";
  
  outputs =
    {
      nixpkgs,
      disko,
      # sops-nix,
      ...
    }:
    {
      
      nixosConfigurations.hab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          # ./nixosModules
          ./configuration.nix
          # sops-nix.nixosModules.sops
        ];
      };
    };
}
