# modules/core/nix.nix
# Configuration for the Nix daemon, Flakes, garbage collection, and automated maintenance.

{ config, lib, pkgs, ... }:

let
  maint = config.custom.maintenance;
in
{
  # Core Nix daemon settings
  nix.settings = {
    # Enable modern CLI commands and Flakes
    experimental-features = [ "nix-command" "flakes" ];

    # Inline store deduplication: hardlinks identical files upon store path addition
    auto-optimise-store = maint.storeOptimise;

    # Dynamic disk safety: trigger emergency GC if free disk drops below threshold
    min-free = maint.minFreeSpaceGB * 1024 * 1024 * 1024; # e.g. 3 GiB
    max-free = maint.maxFreeSpaceGB * 1024 * 1024 * 1024; # e.g. 10 GiB

    # Allow members of wheel group to interact with the Nix daemon without sudo
    trusted-users = [ "root" "@wheel" ];

    # Warn when dirty Git working trees are evaluated in Flakes
    warn-dirty = false;
  };

  # Periodic background store hardlink optimization
  nix.optimise = {
    automatic = maint.storeOptimise;
    dates = [ "weekly" ];
  };

  # Automated scheduled garbage collection of unreferenced store paths
  nix.gc = lib.mkIf maint.garbageCollection.enable {
    automatic = true;
    dates = maint.garbageCollection.dates;
    options = "--delete-older-than ${maint.garbageCollection.olderThan}";
  };

  # Unattended system auto-upgrade via Flake
  # Rebuilds the system from the designated flake path on a scheduled timer
  # If an upgrade fails to build, NixOS aborts cleanly without touching the current generation
  system.autoUpgrade = lib.mkIf maint.autoUpgrade.enable {
    enable = true;
    flake = maint.autoUpgrade.flake;
    dates = maint.autoUpgrade.dates;
    randomizedDelaySec = maint.autoUpgrade.randomizedDelaySec;
    allowReboot = maint.autoUpgrade.allowReboot;
    flags = [
      "--print-build-logs"
      "--update-input" "nixpkgs"
      "--commit-lock-file"
    ];
  };
}
