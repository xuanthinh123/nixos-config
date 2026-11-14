# modules/hardware/power.nix
# Configuration for system power management and ACPI S3 deep sleep prioritization.

{ config, lib, ... }:

let
  cfg = config.custom.hardware.power;
in
{
  config = lib.mkIf cfg.s3Sleep {
    # Instruct Linux kernel command line to select deep sleep (ACPI S3) as default
    boot.kernelParams = [ "mem_sleep_default=deep" ];

    # Configure systemd sleep settings using RFC 0042 structured configuration
    systemd.sleep.settings.Sleep = {
      # Prioritize S3 deep sleep (Suspend-to-RAM) over s2idle modern standby
      MemorySleepMode = "deep";
      AllowSuspend = "yes";
      AllowHibernation = "yes";
      # Graceful fallback: transition to hibernation if suspended for extended periods
      HibernateDelaySec = "30m";
    };
  };
}
