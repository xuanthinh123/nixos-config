# modules/hardware/nvidia.nix
# Configuration for NVIDIA graphics with official proprietary drivers and hybrid PRIME offload.
# Closed-source proprietary drivers are strictly enforced per R2 specification.

{ config, lib, pkgs, ... }:

let
  cfg = config.custom.hardware.nvidia;
in
{
  config = lib.mkIf cfg.enable {
    # Contract assertion enforcing valid PRIME Bus IDs when PRIME is enabled
    assertions = [
      {
        assertion = cfg.prime.enable -> (cfg.prime.intelBusId != "" && cfg.prime.nvidiaBusId != "");
        message = "NVIDIA PRIME requires valid intelBusId and nvidiaBusId.";
      }
    ];

    # Allow proprietary unfree licenses for official NVIDIA driver and gaming packages
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "nvidia-x11"
        "nvidia-settings"
        "nvidia-persistenced"
        "steam"
        "steam-unwrapped"
        "steam-original"
        "steam-run"
      ];

    # Modern NixOS graphics infrastructure (RFC 0042 / NixOS 24.11+)
    hardware.graphics = { enable = true; enable32Bit = true; };

    # Instruct X11 and Wayland display servers to load the proprietary NVIDIA driver
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      # Mandatory kernel modesetting for modern Wayland compositors (KDE Plasma 6)
      modesetting.enable = true;

      # Enable power management hooks for proper suspend/resume handling
      powerManagement.enable = true;

      # Fine-grained power management: powers down the dGPU completely (0W) when idle
      # Guarded by offload mode to prevent fatal NixOS assertion failures in sync mode
      powerManagement.finegrained = (cfg.prime.enable && cfg.prime.mode == "offload");

      # CRITICAL: Strictly mandate official proprietary driver; reject open-source kernel modules
      open = false;

      # Use official stable LTS driver package from NVIDIA (production branch)
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      # Optimus PRIME hybrid graphics switching configuration
      prime = lib.mkIf cfg.prime.enable {
        # Hardware PCI Bus IDs surveyed from host
        intelBusId = cfg.prime.intelBusId;
        nvidiaBusId = cfg.prime.nvidiaBusId;

        # Battery-saving offload mode: iGPU renders desktop; dGPU renders on-demand
        offload = lib.mkIf (cfg.prime.mode == "offload") {
          enable = true;
          # Provides the 'nvidia-offload' wrapper script in system PATH
          enableOffloadCmd = true;
        };

        # Continuous performance mode: dGPU renders all frames
        sync = lib.mkIf (cfg.prime.mode == "sync") {
          enable = true;
        };
      };
    };

    # Helper script prime-run alias for convenience
    environment.systemPackages = lib.optionals (cfg.prime.enable && cfg.prime.mode == "offload") [
      (pkgs.writeShellScriptBin "prime-run" ''
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only
        exec "$@"
      '')
    ];
  };
}
