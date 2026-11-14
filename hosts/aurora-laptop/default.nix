# hosts/aurora-laptop/default.nix
# Host profile for Acer Aspire A515-58GM (alias for hosts/me profile).

{ ... }:

{
  imports = [
    ../me/default.nix
  ];
}
