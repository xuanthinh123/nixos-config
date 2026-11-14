# modules/desktop/default.nix
# Central aggregator for desktop environment and display manager modules.

{ ... }:

{
  imports = [
    ./kde.nix
    ./display-manager.nix
  ];
}
