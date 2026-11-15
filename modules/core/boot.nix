# modules/core/boot.nix
# Configuration for the pure Linux UEFI bootloader and kernel parameters.
# Non-Linux dual-boot scanning (os-prober) and foreign proprietary drivers are strictly excluded.

{ config, lib, pkgs, ... }:

{
  boot = {
    # Pinned to NixOS Stable LTS default Linux kernel
    kernelPackages = lib.mkDefault pkgs.linuxPackages;

    loader = {
      # Lightweight, pure Linux UEFI systemd-boot bootloader
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = 10;
        consoleMode = "max";
        editor = false;
      };

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      # Strictly disable GRUB to prevent legacy dual-boot scanning
      grub.enable = lib.mkDefault false;
    };

    # Pure Linux kernel parameters
    kernelParams = [
      "quiet"
      "loglevel=3"
      "systemd.default_device_timeout_sec=15"
    ];

    # Enable initrd systemd architecture for modern, fast parallel boot
    initrd.systemd.enable = true;

    # Purge outdated tmp files on system startup
    tmp.cleanOnBoot = true;
  };
}
