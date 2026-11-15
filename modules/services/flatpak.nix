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
      # Flatseal launcher (matching surveyed Flatpak com.github.tchx84.Flatseal)
      (pkgs.writeShellScriptBin "flatseal" ''
        # Priority 1: Check for native Nix binary first outside this wrapper
        TARGET_BIN="$(type -a -p flatseal 2>/dev/null | grep -vFx "$0" | head -n1)"
        if [ -n "$TARGET_BIN" ] && [ -x "$TARGET_BIN" ]; then
          exec "$TARGET_BIN" "$@"
        fi

        # Priority 2: Fallback to Flatpak Flathub if native Nix package is not installed
        if command -v flatpak >/dev/null 2>&1; then
          if ! flatpak info com.github.tchx84.Flatseal >/dev/null 2>&1; then
            echo "Native Nix package not found. Installing Flatseal from Flathub fallback..."
            flatpak install -y flathub com.github.tchx84.Flatseal
          fi
          exec flatpak run com.github.tchx84.Flatseal "$@"
        else
          echo "Error: Neither native Nix Flatseal nor Flatpak is available." >&2
          exit 1
        fi
      '')

      kdePackages.flatpak-kcm
    ];
  };
}
