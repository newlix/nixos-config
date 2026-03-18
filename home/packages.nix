{ config, pkgs, ... }:

{
  # ── Shared system packages ────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core tools
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

    bash-completion
    s3cmd
    zola

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

    # Swift
    swiftlint

    # Python
    uv

    # Node.js
    nodejs

    # Backup
    restic
    rclone

    yt-dlp
    jq
    btop
    ncdu
  ];
}
