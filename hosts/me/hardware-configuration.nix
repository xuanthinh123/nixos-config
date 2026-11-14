# hosts/me/hardware-configuration.nix
# Hardware configuration surveyed from the Acer Aspire A515-58GM host machine.
# Pure Linux Btrfs subvolumes layout with dedicated @, @home, @nix, @snapshots, and @swap.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Initrd and kernel modules surveyed from the Acer Aspire A515-58GM hardware
  boot.initrd.availableKernelModules = [
    "xhci_pci"      # USB 3.0 / xHCI controller
    "thunderbolt"   # Thunderbolt 4 controller
    "nvme"          # WD SN740 NVMe SSD controller
    "ahci"          # SATA AHCI controller
    "usbhid"        # USB Human Interface Devices
  ];
  boot.initrd.kernelModules = [ ];

  # Processor kernel modules: 13th Gen Intel Core i5-13420H (Raptor Lake)
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Pure Linux Btrfs subvolume layout with transparent zstd compression
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/.snapshots" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=@snapshots" "compress=zstd" "noatime" ];
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=@swap" "noatime" ];
  };

  # Pure Linux UEFI boot partition (ESP FAT32)
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # Swap devices: zramSwap handles compressed RAM swap; no physical swap partition needed
  swapDevices = [ ];

  # Dynamic DHCP across detected network interfaces (Intel WiFi + Realtek RTL8111 GbE)
  networking.useDHCP = lib.mkDefault true;

  # Host platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Intel CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
