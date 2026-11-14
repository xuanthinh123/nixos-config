# modules/services/distrobox.nix
# Configuration for Podman and Distrobox container engine.
# Provides mutable container environments (Ubuntu, Arch, Fedora) for software not yet packaged in Nixpkgs.

{ config, lib, pkgs, ... }:

let
  cfg = config.custom.services.distrobox;
in
{
  config = lib.mkIf cfg {
    # Enable rootless Podman virtualisation subsystem
    virtualisation.podman = {
      enable = true;
      # Provide Docker CLI compatibility alias
      dockerCompat = true;
      # Enable internal container DNS resolution
      defaultNetwork.settings.dns_enabled = true;
    };

    # System container CLI tools
    environment.systemPackages = with pkgs; [
      podman
      distrobox
    ];
  };
}
