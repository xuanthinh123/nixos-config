# modules/services/default.nix
# Central aggregator for system services and containerization modules.

{ ... }:

{
  imports = [
    ./flatpak.nix
    ./distrobox.nix
    ./tailscale.nix
    ./nix-ld.nix
  ];
}
