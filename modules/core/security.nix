# modules/core/security.nix
# Security policies, authentication, Polkit, and PAM limits.

{ config, lib, pkgs, ... }:

{
  # Sudo authorization settings
  security.sudo = {
    enable = true;
    # Require password confirmation for privilege escalation
    wheelNeedsPassword = true;
    # Retain security environment variables
    extraConfig = ''
      Defaults env_keep += "SSH_AUTH_SOCK"
      Defaults timestamp_timeout = 15
    '';
  };

  # Polkit service for graphical and unprivileged policy management
  security.polkit = {
    enable = true;
  };

  # Realtime scheduling privilege for PipeWire audio daemon
  security.rtkit = {
    enable = true;
  };

  # PAM security limits to prevent file descriptor starvation during large builds
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      type = "soft";
      item = "nofile";
      value = "65536";
    }
    {
      domain = "@wheel";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }
  ];
}
