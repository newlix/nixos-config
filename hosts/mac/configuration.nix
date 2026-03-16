{ config, pkgs, lib, inputs, ... }:

{
  # ── Nix settings ───────────────────────────────────────────────────────────
  # Determinate Nix manages the daemon; let it handle nix.conf
  nix.enable = false;

  # Allow unfree packages (e.g. some fonts, tools)
  nixpkgs.config.allowUnfree = true;

  # ── System packages ────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    curl wget
    vim
    tmux
    htop
    ripgrep fd
    file
    unzip zip

    # Dev
    go
    gcc
    gnumake
    python3

    # Nix tooling
    nixd
    alejandra
  ];

  # ── macOS defaults ─────────────────────────────────────────────────────────
  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv";
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
  };

  # ── Users ──────────────────────────────────────────────────────────────────
  system.primaryUser = "newlix";
  users.users.newlix = {
    home = "/Users/newlix";
  };

  # ── Security ───────────────────────────────────────────────────────────────
  security.pam.services.sudo_local.touchIdAuth = true;

  # ── Home Manager ───────────────────────────────────────────────────────────
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs; };
    users.newlix = import ./home.nix;
  };

  # Used for backwards compatibility
  system.stateVersion = 6;
}
