# modules/core/default.nix
# Central aggregator for all fundamental core NixOS system modules.

{ ... }:

{
  imports = [
    ./options.nix
    ./nix.nix
    ./boot.nix
    ./system.nix
    ./security.nix
  ];
}
