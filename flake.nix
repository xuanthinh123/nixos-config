# flake.nix
# Central Flake entry point for standardized, fleet-ready NixOS configurations.
# Defaulted strictly to NixOS Stable LTS (24.11) with unstable isolated for selective packages.

{
  description = "Standardized Fleet-Ready NixOS Flake Configuration";

  inputs = {
    # Official NixOS Stable LTS release channel (nixos-24.11) for rock-solid fleet stability
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    # Matching Home Manager stable branch
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secondary unstable channel isolated strictly for cutting-edge packages if needed
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, home-manager, nixpkgs-unstable, ... } @ inputs:
  let
    system = "x86_64-linux";

    # Helper function to generate clean, modular host derivations
    mkHost = { hostName, hostModules ? [] }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        # Pass flake inputs to all system and Home Manager modules
        specialArgs = { inherit inputs; };
        modules = [
          # Shared modular system library
          ./modules/core
          ./modules/hardware
          ./modules/desktop
          ./modules/services
          ./modules/suites
          # Home Manager NixOS module binding
          home-manager.nixosModules.home-manager
          ./modules/home
          # Target host profile
          ./hosts/${hostName}
        ] ++ hostModules;
      };
  in
  {
    # Generic fleet baseline configuration for rapid deployment to new PCs / VMs
    nixosConfigurations.default = mkHost { hostName = "default"; };

    # Primary user machine configuration (Acer Aspire A515-58GM with Intel + NVIDIA RTX 2050)
    nixosConfigurations.me = mkHost { hostName = "me"; };

    # Alias for me profile matching surveyed host name
    nixosConfigurations."aurora-laptop" = self.nixosConfigurations.me;
  };
}
