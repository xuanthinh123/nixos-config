# modules/core/system.nix
# Base system configuration: networking, locales, timezone, and zram compressed memory swap.

{ config, lib, pkgs, ... }:

{
  # System networking configuration
  networking = {
    # Dynamically bind network hostname from the custom option hierarchy
    hostName = config.custom.device.hostName;

    # NetworkManager provides flexible networking for WiFi and Ethernet
    networkmanager.enable = true;

    # Basic firewall protection
    firewall = {
      enable = true;
      # Allow ping packets for network diagnostics
      allowPing = true;
    };
  };

  # Localization and internationalization settings
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  # Timezone configuration matching server/fleet standards
  time.timeZone = lib.mkDefault "UTC";

  # Virtual console font and keymap
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # High-performance zram compressed swap
  # Allocates 50% of physical RAM as zstd-compressed in-memory swap to avoid disk wear and OOM freezes
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
    priority = 100;
  };

  # Modern Linux kernel sysctl performance tunings
  boot.kernel.sysctl = {
    # Swappiness tuning for zram: prefer memory compression over killing processes
    "vm.swappiness" = 100;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };
}
