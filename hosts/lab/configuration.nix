{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../../home/packages.nix
    ../../modules/services/samba.nix
    ../../modules/services/backup.nix
    ../../modules/desktop/niri.nix
    ../../modules/services/keyd.nix
  ];

  # ── Boot ───────────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Keep last 5 NixOS generations in the boot menu
  boot.loader.systemd-boot.configurationLimit = 5;

  boot.kernelPackages = pkgs.linuxPackages; # LTS — avoids NVIDIA driver build failures on kernel bumps

  # ── Networking ─────────────────────────────────────────────────────────────
  networking.hostName = "lab";
  networking.networkmanager.enable = true;

  # ── Time & locale ──────────────────────────────────────────────────────────
  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Input method (fcitx5 + chewing) ───────────────────────────────────────
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mcbopomofo
      fcitx5-gtk
    ];
  };

  # ── Fonts ──────────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    lxgw-wenkai
    nerd-fonts.symbols-only
    hack-font
  ];

  # ── Graphics ───────────────────────────────────────────────────────────────
  hardware.graphics.enable = true;

  nixpkgs.config.allowUnfree = true;

  # NVIDIA RTX 5070 Ti (GB203/Blackwell)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true; # Blackwell mandatory: proprietary module lacks GB2xx support

    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = false;
  };

  # ── CUDA ───────────────────────────────────────────────────────────────────
  hardware.nvidia-container-toolkit.enable = true; # nvidia-container-runtime for Docker

  # ── GNOME settings backend (for Nautilus / GTK apps) ─────────────────────
  programs.dconf.enable = true;

  # ── USB / Removable media ───────────────────────────────────────────────────
  services.gvfs.enable = true; # trash, MTP, network mounts for Nautilus
  services.udisks2.enable = true;
  # NTFS / exFAT support for USB drives
  boot.supportedFilesystems = [ "ntfs" "exfat" ];
  # polkit agent for non-root mount authorization
  security.polkit.enable = true;

  # ── Docker ─────────────────────────────────────────────────────────────────
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # ── Users ──────────────────────────────────────────────────────────────────
  users.users.newlix = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.bash;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" ];
    home = "/home/newlix";
  };

  # Allow wheel group to use sudo without password (remove if unwanted)
  security.sudo.wheelNeedsPassword = false;

  # ── Nix settings ───────────────────────────────────────────────────────────
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      # Automatic GC when disk space is low
      min-free = 5 * 1024 * 1024 * 1024; # 5GB
      max-free = 20 * 1024 * 1024 * 1024; # 20GB
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # ── nix-ld ─────────────────────────────────────────────────────────────────
  # Provides a dynamic linker stub so non-NixOS binaries (e.g. uv-managed
  # Python, pre-built ML wheels) can run without patching.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Chromium / Electron runtime dependencies
    glib
    nss
    nspr
    atk
    cups
    dbus
    libdrm
    gtk3
    pango
    cairo
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    mesa
    libgbm
    expat
    alsa-lib
    at-spi2-atk
    at-spi2-core
    libxkbcommon
    libxcursor
    libxi
    libxrender
    libxtst
  ];

  # ── envfs ────────────────────────────────────────────────────────────────
  # Mounts a FUSE filesystem on /usr/bin and /bin that provides executables
  # from nixpkgs, so scripts with shebangs like #!/usr/bin/env bash just work.
  services.envfs.enable = true;

  # ── Home Manager ───────────────────────────────────────────────────────────
  home-manager = {
    useGlobalPkgs = true; # reuse system nixpkgs, avoids a second eval
    useUserPackages = true; # install user packages to /etc/profiles
    backupFileExtension = "bak"; # back up conflicting dotfiles instead of failing
    extraSpecialArgs = { inherit inputs; };
    users.newlix = import ./home.nix;
  };

  # ── Steam ─────────────────────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    extraPackages = [ pkgs.gamescope ];
  };
  programs.gamescope.enable = true;

  # Wrapper: bwrap in steam uses --chdir "$(pwd)" which fails if cwd
  # is not bind-mounted into the sandbox (e.g. when launched from walker).
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "steam-run" ''
      cd "$HOME"
      exec steam "$@"
    '')
  ];

  # ── SSH ────────────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
    };
  };

  # ── Tailscale ─────────────────────────────────────────────────────────────
  services.tailscale.enable = true;

  # ── Eternal Terminal ─────────────────────────────────────────────────────
  services.eternal-terminal.enable = true;
  networking.firewall.allowedTCPPorts = [ 2022 ];

  system.stateVersion = "25.05";
}
