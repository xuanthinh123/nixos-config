# modules/suites/gaming.nix
# Configuration for clean gaming infrastructure (Steam, GameMode).
# Legacy local game data, Proton prefix directories, and old game configs are strictly excluded per R2.

{ config, lib, pkgs, ... }:

let
  cfg = config.custom.suites.gaming;
in
{
  config = lib.mkIf cfg {
    # Official clean Steam installation with proton support
    programs.steam = {
      enable = true;
      # Open firewall ports for local network Steam Remote Play if needed
      remotePlay.openFirewall = false;
      # Dedicated local server firewall ports
      dedicatedServer.openFirewall = false;
    };

    # Feral Interactive GameMode daemon for optimizing CPU governor and process priority
    programs.gamemode.enable = true;
    programs.gamemode.settings = {
      general = {
        renice = 10;
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };

    # Supporting packages for clean game launches
    environment.systemPackages = with pkgs; [
      gamescope
      mangohud
    ];
  };
}
