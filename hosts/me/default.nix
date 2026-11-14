# hosts/me/default.nix
# Host configuration profile specifically tailored for user 'me' on the Acer Aspire A515-58GM laptop.
# Features Intel UHD + NVIDIA RTX 2050 Mobile (PRIME offload), Plasma Login Manager, and full dev/gaming suites.

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  custom = {
    device = {
      hostName = "aurora-laptop";
      type = "laptop";
    };

    hardware = {
      # Proprietary NVIDIA graphics configuration with Optimus PRIME offload
      nvidia = {
        enable = true;
        prime = {
          enable = true;
          mode = "offload";
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };

      # ACPI S3 deep sleep prioritization (supported and verified on host)
      power.s3Sleep = true;
    };

    desktop = {
      enable = true;
      environment = "plasma6";
      # Target host uses Plasma Login Manager (/usr/bin/plasmalogin)
      displayManager = "plasma-login-manager";
    };

    suites = {
      development = true;
      gaming = true;
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
      autoUpgrade = {
        enable = true;
        flake = "path:/etc/nixos#me";
        dates = "04:00";
        randomizedDelaySec = "45min";
        allowReboot = false;
      };
      garbageCollection = {
        enable = true;
        dates = "weekly";
        olderThan = "14d";
      };
      storeOptimise = true;
    };
  };

  system.stateVersion = "24.11";
}
