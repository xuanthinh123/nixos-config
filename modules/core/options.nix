# modules/core/options.nix
# Declarative fleet feature toggles and options for NixOS systems.
# All fleet configuration options are unified under the `custom.*` namespace.

{ lib, ... }:

{
  options.custom = {
    # Device identity and form-factor configuration
    device = {
      hostName = lib.mkOption {
        type = lib.types.str;
        default = "nixos";
        description = "Network hostname assigned to this system.";
      };

      type = lib.mkOption {
        type = lib.types.enum [ "laptop" "desktop" "server" "vm" ];
        default = "laptop";
        description = "Hardware form factor of the machine, affecting power management and default profiles.";
      };
    };

    # Hardware abstraction options (GPU, power management, filesystems)
    hardware = {
      nvidia = {
        enable = lib.mkEnableOption "NVIDIA proprietary graphics driver stack";

        prime = {
          enable = lib.mkEnableOption "NVIDIA Optimus PRIME hybrid graphics switching";

          mode = lib.mkOption {
            type = lib.types.enum [ "offload" "sync" ];
            default = "offload";
            description = "PRIME execution mode: 'offload' keeps dGPU asleep until needed; 'sync' powers dGPU continuously.";
          };

          intelBusId = lib.mkOption {
            type = lib.types.str;
            default = "PCI:0:2:0";
            description = "PCI Bus ID of the Intel integrated GPU in PCI:BUS:SLOT:FUNCTION format.";
          };

          nvidiaBusId = lib.mkOption {
            type = lib.types.str;
            default = "PCI:1:0:0";
            description = "PCI Bus ID of the NVIDIA discrete GPU in PCI:BUS:SLOT:FUNCTION format.";
          };
        };
      };

      power = {
        s3Sleep = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Prioritize ACPI S3 deep sleep (Suspend-to-RAM) over modern standby (s2idle).";
        };
      };
    };

    # Desktop environment and display manager options
    desktop = {
      enable = lib.mkEnableOption "KDE Plasma 6 graphical desktop environment";

      environment = lib.mkOption {
        type = lib.types.enum [ "plasma6" ];
        default = "plasma6";
        description = "Desktop environment session to deploy.";
      };

      displayManager = lib.mkOption {
        type = lib.types.enum [ "plasma-login-manager" "sddm" ];
        default = "plasma-login-manager";
        description = "Display manager service: 'plasma-login-manager' (plasmalogin matching host Aurora OS) or 'sddm' (standard fallback).";
      };
    };

    # Application suites toggles
    suites = {
      development = lib.mkEnableOption "Developer environment suite (Git, Direnv, Mise, Rust, Python, compilers)";
      gaming = lib.mkEnableOption "Gaming suite (Steam, GameMode, zero legacy configs)";
      guiApps = lib.mkEnableOption "Desktop GUI applications (browsers, LibreOffice, KDE utilities, Discover store)";
      cliTools = lib.mkEnableOption "Modern CLI utilities (nh search, comma, nix-index, starship, bat, eza)";
    };

    # System-level services and container runtimes
    services = {
      flatpak = lib.mkEnableOption "Flatpak service with Flathub integration";
      distrobox = lib.mkEnableOption "Rootless Podman and Distrobox container engine";
      tailscale = lib.mkEnableOption "Tailscale VPN daemon and KTailctl GUI integration";
      nixLd = lib.mkEnableOption "Dynamic linker shim (nix-ld) for foreign FHS binaries";
    };

    # Fleet automated maintenance and self-healing policies
    maintenance = {
      autoUpgrade = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable periodic unattended system upgrades via Flakes.";
        };

        flake = lib.mkOption {
          type = lib.types.str;
          default = "path:/etc/nixos#default";
          description = "Flake URI or local path targeted by the automated upgrade service.";
        };

        dates = lib.mkOption {
          type = lib.types.str;
          default = "04:00";
          description = "Systemd OnCalendar time specification for upgrade runs.";
        };

        randomizedDelaySec = lib.mkOption {
          type = lib.types.str;
          default = "45min";
          description = "Random delay added to upgrade timer to prevent fleet network congestion.";
        };

        allowReboot = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Allow automatic reboot following kernel/system upgrades.";
        };
      };

      garbageCollection = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable automated background garbage collection of unreferenced store paths.";
        };

        dates = lib.mkOption {
          type = lib.types.str;
          default = "weekly";
          description = "Systemd OnCalendar schedule for garbage collection runs.";
        };

        olderThan = lib.mkOption {
          type = lib.types.str;
          default = "14d";
          description = "Retention period for historical Nix generations before pruning.";
        };
      };

      storeOptimise = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic inline and background hardlink store deduplication.";
      };

      minFreeSpaceGB = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Minimum free disk space threshold (in GiB) before triggering emergency GC.";
      };

      maxFreeSpaceGB = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = "Target free disk space (in GiB) to recover during emergency GC.";
      };
    };
  };
}
