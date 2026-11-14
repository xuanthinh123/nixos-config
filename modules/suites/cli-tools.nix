# modules/suites/cli-tools.nix
# Configuration for modern CLI utilities, interactive package discovery, and terminal enhancement.

{ config, lib, pkgs, ... }:

let
  cfg = config.custom.suites.cliTools;
in
{
  config = lib.mkIf cfg {
    # Modern Nix CLI helper providing interactive search (`nh search`) and clean rebuilds
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 3";
      };
    };

    # Local LLM service daemon (Ollama)
    services.ollama = {
      enable = true;
    };

    # Real-time nix-index database for rapid package searching and command-not-found integration
    programs.nix-index.enable = true;

    # Cross-shell modern prompt
    programs.starship = {
      enable = true;
    };

    # High-productivity terminal utilities matching host survey
    environment.systemPackages = with pkgs; [
      # On-the-fly binary runner (e.g. `, cowsay hello`)
      comma

      # Fast interactive Nixpkgs search utility
      nix-search-cli

      # Modern Unix tool replacements
      bat       # Cat with syntax highlighting and git integration
      btop      # Resource monitor
      eza       # Modern ls replacement
      fd        # Fast find replacement
      ripgrep   # Fast grep replacement
      tealdeer  # Fast tldr client
      zoxide    # Smarter cd command
      atuin     # Shell history sync and search
      trash-cli # Safe rm replacement
      chezmoi   # Dotfiles management tool
      podman-tui# Terminal UI for Podman containers
      dysk      # Linux disk allocation viewer
      aria2     # Multi-protocol high-speed download utility
      ollama    # Local LLM runner for local AI models

      # Data processing utilities
      jq
      yq
      fzf
    ];
  };
}
