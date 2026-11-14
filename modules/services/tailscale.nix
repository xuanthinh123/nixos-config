# modules/services/tailscale.nix
# Configuration for Tailscale mesh VPN daemon and KDE Plasma GUI integration.

{ config, lib, pkgs, ... }:

let
  cfg = config.custom.services.tailscale;
in
{
  config = lib.mkIf cfg {
    # System-level Tailscale VPN service daemon
    services.tailscale.enable = true;
    services.tailscale.useRoutingFeatures = "client";

    # Tailscale CLI client and native KDE Plasma graphical control utility
    environment.systemPackages = with pkgs; [
      tailscale
      ktailctl
    ];

    # Open Tailscale network ports in system firewall
    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      checkReversePath = "loose";
    };
  };
}
