# modules/home/default.nix
# Home Manager NixOS module integration and user account provisioning.

{ config, lib, pkgs, inputs, ... }:

{
  # Provision the primary normal user account matching host
  users.users.me = {
    isNormalUser = true;
    description = "User";
    extraGroups = [
      "wheel"           # Sudo / administrative rights
      "networkmanager"  # Network configuration
      "video"           # Hardware video acceleration
      "audio"           # Audio device access
      "podman"          # Rootless container management
    ];
    shell = pkgs.bash;
  };

  # Home Manager NixOS module options
  home-manager = {
    # Use system-level nixpkgs packages rather than a separate Home Manager evaluation
    useGlobalPkgs = true;

    # Install user packages directly into /etc/profiles/per-user/me for consistent PATH
    useUserPackages = true;

    # Automatically rename conflicting dotfiles with .backup rather than failing the build
    backupFileExtension = "backup";

    # Pass inputs and specialArgs to Home Manager submodules
    extraSpecialArgs = { inherit inputs; };

    # Map user configuration module
    users.me = import ./users/me.nix;
  };
}
