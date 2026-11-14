# modules/home/users/me.nix
# User-level configuration for user 'me' managed by Home Manager.
# Encapsulates dotfiles, shells (Bash, Zsh, Fish), Git, Starship, and build environment variables.

{ config, lib, pkgs, ... }:

{
  home.username = "me";
  home.homeDirectory = "/home/me";

  # Home Manager state version
  home.stateVersion = "24.11";

  # User binary search paths ensuring Antigravity (agy), Grok, OpenCode, and local CLI tools are globally in PATH
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.grok/bin"
    "$HOME/.opencode/bin"
    "$HOME/.gemini/antigravity-cli/bin"
  ];

  # Global user environment variables matching surveyed Aurora OS environment
  home.sessionVariables = {
    # Compilation parallelization tuned for the 12-core Intel i5-13420H
    MAKEFLAGS = "-j12";
    CMAKE_BUILD_PARALLEL_LEVEL = "12";

    # Global developer telemetry opt-outs
    DO_NOT_TRACK = "1";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    NEXT_TELEMETRY_DISABLED = "1";
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    SAM_CLI_TELEMETRY = "0";
    GOTELEMETRY = "off";
    AZURE_CORE_COLLECT_TELEMETRY = "0";
    HF_HUB_DISABLE_TELEMETRY = "1";

    # Centralized Python bytecode cache to prevent __pycache__ pollution in source repos
    PYTHONPYCACHEPREFIX = "$HOME/.cache/cpython";

    # UV package manager performance tuning
    UV_CACHE_DIR = "$HOME/.cache/uv";
    UV_LINK_MODE = "clone";
    UV_CONCURRENT_DOWNLOADS = "8";
    UV_CONCURRENT_BUILDS = "12";
    UV_CONCURRENT_INSTALLS = "12";

    # Memory allocation arena limit
    MALLOC_ARENA_MAX = "4";

    # Node.js maximum heap space
    NODE_OPTIONS = "--max-old-space-size=4096";

    # Pager configuration
    PAGER = "less";
    LESS = "-R -F -X -i";
  };

  # Shell configuration: Bash
  programs.bash.enable = true;
  programs.bash = {
    historySize = 50000;
    historyFileSize = 100000;
    historyControl = [ "ignoreboth" "erasedups" ];
    shellAliases = {
      ls = "eza --icons";
      ll = "eza -la --icons";
      cat = "bat";
      find = "fd";
      grep = "ripgrep";
    };
  };

  # Shell configuration: Zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ls = "eza --icons";
      ll = "eza -la --icons";
      cat = "bat";
    };
  };

  # Shell configuration: Fish
  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "eza --icons";
      ll = "eza -la --icons";
      cat = "bat";
    };
  };

  # Cross-shell modern prompt (Starship)
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      scan_timeout = 10;
      command_timeout = 200;
      # Disable slow cloud / package prompt indicators for high terminal responsiveness
      package.disabled = true;
      aws.disabled = true;
      gcloud.disabled = true;
      azure.disabled = true;
    };
  };

  # Git VCS configuration
  programs.git = {
    enable = true;
    userName = "xuanthinh123";
    userEmail = "thinhzhv123@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      fetch.prune = true;
      # Performance optimisations for large multi-agent and code repositories
      core = {
        preloadindex = true;
        fscache = true;
        untrackedCache = true;
      };
      feature.manyFiles = true;
      index.threads = true;
      pack.threads = 0;
    };
  };

  # Mise polyglot toolchain configuration matching host survey with pinned Go LTS
  xdg.configFile."mise/config.toml".text = ''
    [tools]
    go = "1.23"
    java = "temurin-21"
    node = "24.22.0"
  '';

  # Fontconfig integration: Automatically indexes and discovers all custom user fonts in ~/.local/share/fonts
  fonts.fontconfig.enable = true;

  # Let Home Manager manage its own installation
  programs.home-manager.enable = true;
}
