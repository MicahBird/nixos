{
  description = "A very basic flake (shocking I know)";

  inputs = {
    # NixOS official package source, using the nixos-24.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS/?ref=1129c951dcc2a269a12cb74d64bd64e44e724ecb";
      inputs.nixpkgs.follows = "chaotic/jovian";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nix-flatpak, chaotic, jovian, ... }@inputs: {
    # Bricolage is a main workstation
    nixosConfigurations.bricolage = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # Set all inputs parameters as special arguments for all submodules,
      # so you can directly use all dependencies in inputs in submodules
      specialArgs = { inherit inputs; };
      modules = [
        nix-flatpak.nixosModules.nix-flatpak
        ./machines/bricolage/configuration.nix
      ];
    };
    # Haggstrom is a gaming spesific config
    nixosConfigurations.haggstrom = nixpkgs-unstable.lib.nixosSystem { # NOTE: MUST USE UNSTABLE
      system = "x86_64-linux";
      # Set all inputs parameters as special arguments for all submodules,
      # so you can directly use all dependencies in inputs in submodules
      specialArgs = { inherit inputs; };
      modules = [
        inputs.jovian.nixosModules.default
        chaotic.nixosModules.default
        nix-flatpak.nixosModules.nix-flatpak
        ./machines/haggstrom/configuration.nix
      ];
    };
  };
}
