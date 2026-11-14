# modules/hardware/default.nix
# Central aggregator for hardware abstraction modules.

{ ... }:

{
  imports = [
    ./nvidia.nix
    ./power.nix
    ./filesystem.nix
  ];
}
