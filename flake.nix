{
  description = "A very basic flake (shocking I know)";

  inputs = {
    # NixOS official package source, using the nixos-24.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    jovian = {
      url =
        "github:Jovian-Experiments/Jovian-NixOS/?ref=04ce5c103eb621220d69102bc0ee27c3abd89204";
      inputs.nixpkgs.follows = "chaotic/jovian";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
    # Dormlab components

    # nixos-router = {
    #   url = "github:chayleaf/nixos-router/?ref=0cf86070433a69012d33fa21fe9a899247b15073";
    # };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nix-flatpak, chaotic, jovian, ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
      username = "snowflake";
    in {
      # Bricolage is a main workstation
      nixosConfigurations.bricolage = nixpkgs.lib.nixosSystem {
        inherit system;
        # Set all inputs parameters as special arguments for all submodules,
        # so you can directly use all dependencies in inputs in submodules
        specialArgs = { inherit inputs; };
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          ./machines/bricolage/configuration.nix
        ];
      };
      # Haggstrom is a gaming spesific config
      nixosConfigurations.haggstrom =
        nixpkgs-unstable.lib.nixosSystem { # NOTE: MUST USE UNSTABLE
          inherit system;
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
      nixosConfigurations.dormlab = nixpkgs.lib.nixosSystem {
        inherit system;
        # Set all inputs parameters as special arguments for all submodules,
        # so you can directly use all dependencies in inputs in submodules
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit pkgs-unstable;
        };
        modules = [
          # inputs.nixos-router.nixosModules.default
          ./modules/cli.nix
          ./machines/dormlab/configuration.nix
        ];
      };
    };
}
