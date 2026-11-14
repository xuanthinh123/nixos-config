# modules/services/flatpak.nix
# Configuration for Flatpak daemon and automatic Flathub remote repository registration.

{ config, lib, pkgs, ... }:

let
  cfg = config.custom.services.flatpak;
in
{
  config = lib.mkIf cfg {
    # System-level Flatpak daemon service
    services.flatpak.enable = true;

    # Declarative oneshot systemd unit to register the official Flathub remote repository
    systemd.services.configure-flathub = {
      description = "Add Flathub remote repository to Flatpak";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo";
        RemainAfterExit = true;
      };
    };

    # Flatpak permission management GUI and KDE System Settings module
    environment.systemPackages = with pkgs; [
      flatseal
      kdePackages.flatpak-kcm
    ];
  };
}
