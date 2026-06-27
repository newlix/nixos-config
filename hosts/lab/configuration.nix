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

  # Shutdown watchdog — forces reboot after 5 min if shutdown hangs (e.g. FUSE unmount).
  systemd.settings.Manager.ShutdownWatchdogSec = "5min";

  # Blacklist xpad: clone controllers have known kernel hang on unplug.
  # Fall back to usbhid + Steam Input for all controllers.
  boot.blacklistedKernelModules = [ "xpad" ];

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
  nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];

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

  # Nautilus draws a hardcoded filmstrip overlay on video thumbnails using the
  # embedded src/resources/image/filmholes.png resource. Replace it with a 1x1
  # transparent PNG before the gresource bundle is built.
  nixpkgs.overlays = [
    (final: prev: {
      nautilus = prev.nautilus.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          base64 -d > src/resources/image/filmholes.png <<'PNG'
          iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkAAIAAAoAAv/lxKUAAAAASUVORK5CYII=
          PNG
        '';
      });
    })
  ];

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
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "input" ];
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

  # ── /usr/bin ─────────────────────────────────────────────────────────────
  # environment.usrbinenv (default: pkgs.coreutils/bin/env) already creates
  # /usr/bin/env.  envfs (FUSE) was disabled because mount.envfs survived
  # umount on shutdown and blocked the final reboot pivot.

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

  # Enable joycond for Nintendo Switch controllers
  services.joycond.enable = true;

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
