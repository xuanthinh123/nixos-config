# modules/desktop/display-manager.nix
# Modular display manager configuration supporting Plasma Login Manager (host parity) and SDDM fallback.

{ config, lib, pkgs, ... }:

let
  cfg = config.custom.desktop;
in
{
  config = lib.mkIf cfg.enable {
    services.displayManager = {
      # Target host Aurora OS uses plasma-login-manager (/usr/bin/plasmalogin)
      plasma-login-manager = lib.mkIf (cfg.displayManager == "plasma-login-manager") {
        enable = true;
      };

      # SDDM display manager with Wayland greeter enabled as a standardized fleet fallback
      sddm = lib.mkIf (cfg.displayManager == "sddm") {
        enable = true;
        wayland.enable = true;
      };
    };

    # Install SDDM KDE Control Module when SDDM is active
    environment.systemPackages = lib.optionals (cfg.displayManager == "sddm") [
      pkgs.kdePackages.sddm-kcm
    ];
  };
}
