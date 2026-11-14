# modules/suites/development.nix
# Configuration for developer environments, compilers, runtimes, and VCS tools matching host survey.

{ config, lib, pkgs, ... }:

let
  cfg = config.custom.suites.development;
in
{
  config = lib.mkIf cfg {
    # System-level Direnv integration with fast nix-direnv caching
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Developer toolchain packages
    environment.systemPackages = with pkgs; [
      # Version control
      git
      gh
      lazygit

      # Polyglot runtime manager (Go, Node, Java as surveyed on host)
      mise

      # Rust toolchain
      rustc
      cargo
      rustfmt
      clippy

      # Python ecosystem
      python3
      uv

      # C/C++ build tools and compilers
      gcc
      clang
      gnumake
      cmake
      ninja
      pkg-config

      # Editors and formatting
      neovim
      tree-sitter
    ];
  };
}
