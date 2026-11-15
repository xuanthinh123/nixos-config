# hosts/vm/default.nix
# Dedicated host profile optimized for Virtual Machines (QEMU/KVM, VirtualBox, VMware).
# Disables proprietary dGPU drivers and physical laptop S3 sleep; adds VM guest integration.
# Standardized on modern pure Linux UEFI (systemd-boot).

{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  custom = {
    device = {
      hostName = "nixos-vm";
      type = "vm";
    };

    hardware = {
      # No discrete NVIDIA GPU in standard VM
      nvidia.enable = false;
      # Disable physical ACPI S3 deep sleep for VM virtual hardware
      power.s3Sleep = false;
    };

    desktop = {
      enable = true;
      environment = "plasma6";
      displayManager = "sddm";
    };

    suites = {
      development = true;
      gaming = false;
      guiApps = true;
      cliTools = true;
    };

    services = {
      flatpak = true;
      distrobox = true;
      tailscale = true;
      nixLd = true;
    };

    maintenance = {
      autoUpgrade.enable = false;
      garbageCollection.enable = true;
      storeOptimise = true;
    };
  };

  # Virtual machine guest integrations
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Pinned state version
  system.stateVersion = "24.11";
}
