# hosts/aurora-laptop/hardware-configuration.nix
# Hardware configuration alias referencing hosts/me hardware definition.

{ ... }:

{
  imports = [
    ../me/hardware-configuration.nix
  ];
}
