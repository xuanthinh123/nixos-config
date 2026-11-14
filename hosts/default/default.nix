# hosts/default/default.nix
# Minimal generic host profile for fleet baseline deployment.
# Can be deployed to standard desktops, laptops with integrated GPUs, or virtual machines.

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  custom = {
    device = {
      hostName = "nixos-default";
      type = "desktop";
    };

    hardware = {
      # Generic fleet baseline defaults to non-NVIDIA (Intel/AMD/VM)
      nvidia.enable = false;
      power.s3Sleep = true;
    };

    desktop = {
      enable = true;
      environment = "plasma6";
      displayManager = "sddm"; # Generic baseline uses standard SDDM Wayland
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
      autoUpgrade.enable = true;
      garbageCollection.enable = true;
      storeOptimise = true;
    };
  };

  system.stateVersion = "24.11";
}
