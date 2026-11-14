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

    # Configure systemd sleep settings for deep sleep (Suspend-to-RAM)
    systemd.sleep.extraConfig = ''
      AllowSuspend=yes
      AllowHibernation=yes
      HibernateDelaySec=30m
      SuspendState=mem
    '';
  };
}
