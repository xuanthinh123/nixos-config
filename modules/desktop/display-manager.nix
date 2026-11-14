# modules/desktop/display-manager.nix
# Modular display manager configuration using standard SDDM with Wayland greeter for KDE Plasma 6.

{ config, lib, pkgs, ... }:

let
  cfg = config.custom.desktop;
in
{
  config = lib.mkIf cfg.enable {
    services.displayManager = {
      # Standard SDDM display manager with Wayland greeter for KDE Plasma 6
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
