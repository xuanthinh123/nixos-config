# modules/suites/default.nix
# Central aggregator for optional application and tooling suites.

{ ... }:

{
  imports = [
    ./development.nix
    ./gaming.nix
    ./gui-apps.nix
    ./cli-tools.nix
  ];
}
