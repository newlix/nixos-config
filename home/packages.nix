{ config, lib, pkgs, inputs, ... }:

{
  # ── Shared system packages ────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core tools
    git
    curl wget
    fresh-editor

    helix
    tmux
    htop
    ripgrep fd
    unzip zip unrar p7zip

    # Dev
    gcc
    sqlite            # interactive SQLite CLI
    shellcheck         # Shell script linter
    typos              # Code spell checker
    # JS/TS linting (OMP BiomeClient)
    biome              # Fast linter + formatter
    # Nix linting
    statix             # Nix anti-pattern linter
    deadnix            # Unused Nix code scanner
    bash-completion
    s3cmd
    zola
    antigravity-ide     # Google agentic IDE
    wrangler       # Cloudflare Workers CLI

    # Nix tooling
    nixd           # LSP for Nix
    alejandra      # Nix formatter
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    # Android / Jetpack Compose
    android-studio-full
    android-tools
    jdk17
    kotlin
    gradle

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
    ctx7

    # LSPs
    sqls
    taplo
    kotlin-language-server
    lemminx           # XML LSP (AndroidManifest, layouts, etc.)
    # Go
    gopls
    golangci-lint-langserver  # Go lint LSP (Helix)
    go-tools # staticcheck
    sqlc

    # Python
    python3
    uv

    # Node.js
    nodejs
    pnpm
    typescript-language-server
    vscode-js-debug   # JS/TS debug adapter (OMP)

    # Backup
    restic
    rclone

    # CLI tools
    yt-dlp
    jq
    btop
    ncdu
    zoxide    # smart cd replacement
    nix-index # nix-index for command-not-found
    uv        # python manager (was ~/.local/bin nix-ld prebuilt)
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    swiftlint
  ] ++ lib.optionals pkgs.stdenv.isLinux (with pkgs; [
    # opencode pinned ahead of nixpkgs (loop-bug fix); revert to plain
    # `opencode` in the common list once nixpkgs >= 1.18.18
    (import ../packages/opencode-bin.nix { inherit pkgs; })
    ktfmt
    scrcpy
    bc

    # Niri ecosystem
    waybar
    foot
    fuzzel
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
    papirus-icon-theme


    # Screenshot
    swappy

    # Communication
    telegram-desktop

    # XWayland
    xwayland-satellite

    # Notifications
    libnotify

    # Music (uses mpv now)
    playerctl

    # Notes
    (import ../packages/bun.nix { inherit pkgs; })
    (import ../packages/scratch.nix { inherit pkgs; })
    (import ../packages/azaharplus.nix { inherit pkgs; })
  ]);
}
