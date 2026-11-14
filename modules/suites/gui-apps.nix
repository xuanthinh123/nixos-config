# modules/suites/gui-apps.nix
# Configuration for desktop GUI productivity applications and KDE Discover App Store.

{ config, lib, pkgs, ... }:

let
  cfg = config.custom.suites.guiApps;
in
{
  config = lib.mkIf cfg {
    environment.systemPackages = with pkgs; [
      # Web Browsers
      chromium

      # Zen Browser launcher: prioritizes native Nix package, fallbacks gracefully to Flatpak
      (pkgs.writeShellScriptBin "zen" ''
        # Priority 1: Check for native Nix binary first
        if [ -x "$(command -v zen-browser 2>/dev/null)" ] && [ "$(command -v zen-browser)" != "$0" ]; then
          exec zen-browser "$@"
        fi

        # Priority 2: Fallback to Flatpak Flathub if native Nix package is not installed
        if command -v flatpak >/dev/null 2>&1; then
          if ! flatpak info app.zen_browser.zen >/dev/null 2>&1; then
            echo "Native Nix package not found. Installing Zen Browser from Flathub fallback..."
            flatpak install -y flathub app.zen_browser.zen
          fi
          exec flatpak run app.zen_browser.zen "$@"
        else
          echo "Error: Neither native Nix Zen Browser nor Flatpak is available." >&2
          exit 1
        fi
      '')

      # Office & Productivity (LTS still branch)
      libreoffice-qt6-still

      # Simplenote launcher (matching surveyed Flatpak com.simplenote.Simplenote)
      (pkgs.writeShellScriptBin "simplenote" ''
        if command -v flatpak >/dev/null 2>&1; then
          if ! flatpak info com.simplenote.Simplenote >/dev/null 2>&1; then
            echo "Installing Simplenote from Flathub..."
            flatpak install -y flathub com.simplenote.Simplenote
          fi
          exec flatpak run com.simplenote.Simplenote "$@"
        else
          echo "Error: Flatpak is required to run Simplenote." >&2
          exit 1
        fi
      '')

      # Virtualization and Utilities from host survey
      gnome-boxes           # Simple VM manager matching Flatpak Boxes
      ktailctl              # Tailscale system tray GUI
      neovide               # Advanced graphical UI for Neovim
      protonvpn-gui         # Official Proton VPN client GUI

      # Graphical Software Center (Discover backed by Flatpak)
      kdePackages.discover

      # Surveyed KDE Multimedia and Productivity Applications
      kdePackages.gwenview # Image viewer
      haruna               # Video / media player
      kdePackages.kcalc    # Calculator
      kdePackages.kclock   # Clock and timer
      kdePackages.kdenlive # Video editor
      kdePackages.ktorrent # BitTorrent client
      kdePackages.okular   # Document and PDF viewer
      kdePackages.kate     # Advanced text editor
    ];
  };
}
