{ config, lib, pkgs, ... }:

{
  # ── Shared system packages ────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core tools
    git
    curl wget
    vim
    helix
    tmux
    htop
    ripgrep fd
    file lsof psmisc
    unzip zip

    # Dev
    go
    gcc
    gnumake
    bash-completion
    s3cmd
    zola

    # VNC (headless browser auth)
    xorg.xorgserver  # Xvfb
    x11vnc

    # Nix tooling
    nixd           # LSP for Nix
    alejandra      # Nix formatter
  ];

  # ── Shared user packages (home-manager) ───────────────────────────────────
  home-manager.users.newlix.home.packages = with pkgs; [
    gh
    claude-code
    gemini-cli-bin

    # Go
    gopls
    golangci-lint
    go-tools # staticcheck

    # Swift (macOS only)
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    swiftlint
  ] ++ (with pkgs; [

    # Python
    uv

    # Node.js
    nodejs

    # Backup
    restic
    rclone

    # Niri ecosystem
    waybar
    foot
    walker
    elephant
    swaybg
    pavucontrol
    swaylock-effects

    # Browser
    google-chrome

    # Media
    celluloid

    # File manager
    nautilus

    # Image viewer
    loupe

    # Calendar
    gnome-calendar

    yt-dlp
    jq
    btop
    ncdu
  ]);
}
