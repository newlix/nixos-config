{ config, lib, pkgs, ... }:

{
  # ── Shared system packages ────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core tools
    git
    curl wget
    fresh-editor
    vim
    helix
    tmux
    htop
    ripgrep fd
    file lsof
    unzip zip

    # Dev
    go
    gcc
    gnumake
    bash-completion
    s3cmd
    zola

    # Nix tooling
    nixd           # LSP for Nix
    alejandra      # Nix formatter
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    psmisc
    xorg-server  # Xvfb
    x11vnc
    adwaita-icon-theme
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
    sqlc

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

    # Editor
    fresh-editor

    yt-dlp
    jq
    btop
    ncdu
  ]) ++ lib.optionals pkgs.stdenv.isLinux (with pkgs; [

    # Niri ecosystem
    waybar
    foot
    walker
    elephant
    pavucontrol
    swaylock-effects

    # Browser
    google-chrome

    # File manager
    nautilus
    ffmpegthumbnailer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
    papirus-icon-theme
    dconf

    # Image viewer
    loupe

    # Screenshot
    swappy

    # Communication
    telegram-desktop

    # XWayland
    xwayland-satellite

    # Notifications
    mako
    libnotify

    # Music
    amberol

    # Editor
    sublime4
    zed-editor
    playerctl
  ]);
}
