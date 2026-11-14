# modules/hardware/filesystem.nix
# Configuration for pure native Linux filesystems.
# Foreign non-Linux drivers and mounts are strictly excluded.

{ config, lib, pkgs, ... }:

{
  boot = {
    # Whitelist of native Linux filesystems supported by the kernel
    supportedFilesystems = [
      "btrfs"
      "ext4"
      "xfs"
    ];
  };

  # Essential pure Linux filesystem management utilities
  environment.systemPackages = with pkgs; [
    btrfs-progs
    e2fsprogs
    xfsprogs
    dosfstools # For managing UEFI FAT32 EFI System Partitions (/boot)
  ];
}
