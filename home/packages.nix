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
    xorg-server  # Xvfb
    x11vnc

    # Nix tooling
    nixd           # LSP for Nix
    alejandra      # Nix formatter
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
    fresh-editor
    sublime4
    zed-editor
    playerctl

    yt-dlp
    jq
    btop
    ncdu
  ]);
}
