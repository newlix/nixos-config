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
    unzip zip unrar

    # Dev
    gcc
    gnumake
    bash-completion
    s3cmd
    zola

    # Nix tooling
    nixd           # LSP for Nix
    alejandra      # Nix formatter
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    libfaketime
    scanmem        # memory scanner (like Cheat Engine)
    file lsof
    psmisc         # killall, fuser, pstree
    adwaita-icon-theme
    # VNC (headless browser auth)
    xorg-server  # Xvfb
    x11vnc
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

    # Python
    uv

    # Node.js
    nodejs
    pnpm
    typescript-language-server

    # Backup
    restic
    rclone

    # CLI tools
    yt-dlp
    jq
    btop
    ncdu
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    swiftlint
  ] ++ lib.optionals pkgs.stdenv.isLinux (with pkgs; [
    bc

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
    file-roller
    ffmpegthumbnailer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
    papirus-icon-theme

    # Image viewer
    loupe

    # Screenshot
    swappy

    # Communication
    telegram-desktop

    # XWayland
    xwayland-satellite

    # Notifications
    libnotify

    # Music
    amberol
    playerctl

    # Notes
    (import ../packages/scratch.nix { inherit pkgs; })
  ]);
}
