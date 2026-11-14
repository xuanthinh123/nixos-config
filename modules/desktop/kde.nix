# modules/desktop/kde.nix
# Configuration for KDE Plasma 6 Wayland desktop session and PipeWire audio stack.

{ config, lib, pkgs, ... }:

let
  cfg = config.custom.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # Core X11 infrastructure required for display managers and XWayland compatibility
    services.xserver.enable = true;

    # Enable KDE Plasma 6 desktop manager on Wayland
    services.desktopManager.plasma6.enable = true;

    # Set default graphical desktop session to modern Wayland
    services.displayManager.defaultSession = "plasma";

    # Modern PipeWire and WirePlumber audio stack
    # Replaces legacy PulseAudio with low-latency pro-audio routing
    services.pipewire.enable = true;
    services.pipewire = {
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # Desktop portal integration for Wayland screen sharing and Flatpak sandbox communication
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    };

    # Essential KDE desktop packages
    environment.systemPackages = with pkgs; [
      kdePackages.plasma-desktop
      kdePackages.plasma-workspace
      kdePackages.wayland-protocols
    ];

    # Explicitly remove default KDE Plasma bloatware (music player, help center, legacy themes)
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      elisa
      khelpcenter
      oxygen
    ];

    # Comprehensive font suite: Developer Nerd Fonts, Vietnamese typography, and system defaults
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        # General desktop, Vietnamese UTF-8, and CJK international typography
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        dejavu_fonts

        # Complete Nerd Fonts suite matching all fonts surveyed from host
        (nerdfonts.override {
          fonts = [
            "0xProto"
            "CascadiaCode"
            "ComicShannsMono"
            "DroidSansMono"
            "FiraCode"
            "Go-Mono"
            "IBMPlexMono"
            "JetBrainsMono"
            "SourceCodePro"
            "Ubuntu"
            "UbuntuMono"
          ];
        })
      ];

      # Default system font aliases for clean desktop typography rendering
      fontconfig = {
        defaultFonts = {
          serif = [ "Noto Serif" "DejaVu Serif" ];
          sansSerif = [ "Noto Sans" "DejaVu Sans" ];
          monospace = [ "JetBrainsMono Nerd Font" "Noto Sans Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };
  };
}
