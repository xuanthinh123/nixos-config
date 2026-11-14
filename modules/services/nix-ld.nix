# modules/services/nix-ld.nix
# Configuration for nix-ld dynamic linker emulation.
# Allows executing unpatched foreign FHS binaries and language servers directly on NixOS.

{ config, lib, pkgs, ... }:

let
  cfg = config.custom.services.nixLd;
in
{
  config = lib.mkIf cfg {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      glib
      openssl
      libglvnd
      vulkan-loader
      xorg.libX11
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXi
      libxkbcommon
      alsa-lib
      udev
    ];
  };
}
