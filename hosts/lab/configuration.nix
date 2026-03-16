{ config, pkgs, lib, inputs, ... }:

{
  # ── Boot ───────────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Keep last 5 NixOS generations in the boot menu
  boot.loader.systemd-boot.configurationLimit = 5;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── Networking ─────────────────────────────────────────────────────────────
  networking.hostName = "lab";
  networking.networkmanager.enable = true;

  # ── Time & locale ──────────────────────────────────────────────────────────
  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Input method (注音) ────────────────────────────────────────────────────
  # fcitx5-chewing = 新酷音，Taiwanese Bopomofo engine
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-chewing  # 注音 / Bopomofo
      fcitx5-gtk      # GTK im module
    ];
  };

  # ── Graphics ───────────────────────────────────────────────────────────────
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;  # required for Steam / Proton

  nixpkgs.config.allowUnfree = true;  # VSCode, Steam, NVIDIA drivers
  nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];
  
  # NVIDIA RTX 5070 Ti (GB203/Blackwell)
  # open = true: Blackwell requires the open-source kernel module (nvidia-open)
  # If the stable driver doesn't yet support GB203, switch to:
  #   hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;   # required for Wayland
    open = true;                 # Blackwell mandatory: proprietary module lacks GB2xx support
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = false;
  };

  # ── CUDA ───────────────────────────────────────────────────────────────────
  hardware.nvidia-container-toolkit.enable = true;  # nvidia-container-runtime for Docker

  # ── Fonts ──────────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only   # fallback icons for any font
  ];

  # ── niri (Wayland compositor) ──────────────────────────────────────────────
  # nixosModules.niri from sodiboo/niri-flake is included in flake.nix modules.
  # It sets up the niri session, polkit, GNOME keyring, and xdg-desktop-portal-gnome.
  programs.niri.enable = true;


  # Login: greetd + tuigreet (TUI greeter, starts a niri Wayland session)
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
      user = "greeter";
    };
  };

  # XDG portals (screen capture, file picker)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # ── Noctalia shell ─────────────────────────────────────────────────────────
  # Required services per https://docs.noctalia.dev/getting-started/nixos/
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # ddcutil: DDC/CI brightness control for external monitors.
  # Requires i2c access — hardware.i2c creates the i2c group + udev rules.
  hardware.i2c.enable = true;

  # ── Sound ──────────────────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

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
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "i2c" ];
    home = "/home/newlix";
  };

  # Allow wheel group to use sudo without password (remove if unwanted)
  security.sudo.wheelNeedsPassword = false;

  # ── Packages ───────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core tools
    git
    curl wget
    vim
    tmux
    htop
    ripgrep fd bat
    file
    unzip zip

    # Dev
    go
    gcc
    gnumake
    python3

    # Wayland utilities
    grim slurp      # screenshots
    wl-clipboard
    foot            # terminal emulator
    xdg-utils xdg-user-dirs

    # Noctalia shell (desktop shell for niri)
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Zen Browser (Firefox-based, not in nixpkgs)
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Nix tooling
    nixd           # LSP for Nix
    alejandra      # Nix formatter
  ];

  # ── Nix settings ───────────────────────────────────────────────────────────
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # niri binary cache — avoids recompiling the compositor locally
      substituters = [ "https://niri.cachix.org" ];
      trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
      auto-optimise-store = true;
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

  # ── Steam ──────────────────────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # ── Home Manager ───────────────────────────────────────────────────────────
  home-manager = {
    useGlobalPkgs = true;    # reuse system nixpkgs, avoids a second eval
    useUserPackages = true;  # install user packages to /etc/profiles
    backupFileExtension = "bak";  # back up conflicting dotfiles instead of failing
    extraSpecialArgs = { inherit inputs; };
    users.newlix = import ./home.nix;
  };

  # ── Samba ──────────────────────────────────────────────────────────────────
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server role" = "standalone server";
        # macOS (AFP over SMB) compatibility
        "vfs objects"                            = "catia fruit streams_xattr";
        "fruit:aapl"                             = "yes";
        "fruit:copyfile"                         = "yes";
        "fruit:model"                            = "MacSamba";
        "fruit:metadata"                         = "stream";
        "fruit:veto_appledouble"                 = "no";
        "fruit:posix_rename"                     = "yes";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles"             = "yes";
        "map to guest"                           = "bad user";
        "usershare allow guests"                 = "no";
        # Disable SMB1 — macOS uses SMB2/3, SMB1 is a security risk
        "server min protocol"                    = "SMB2";
        "server signing"                         = "auto";
      };
      data = {
        path = "/data";
        browseable = "yes";
        "read only" = "no";
        "create mask" = "0700";
        "directory mask" = "0700";
        "valid users" = "newlix";
        "ea support" = "yes";
        "veto files" = "/.DS_Store/.Spotlight-V100/.Trashes/.fseventsd/";
        "delete veto files" = "yes";
      };
      newlix = {
        path = "/home/newlix";
        browseable = "yes";
        "read only" = "no";
        "create mask" = "0700";
        "directory mask" = "0700";
        "valid users" = "newlix";
        "ea support" = "yes";
        "veto files" = "/.DS_Store/.Spotlight-V100/.Trashes/.fseventsd/";
        "delete veto files" = "yes";
      };
      "115" = {
        path = "/115";
        browseable = "yes";
        "read only" = "no";
        "create mask" = "0700";
        "directory mask" = "0700";
        "valid users" = "newlix";
        "ea support" = "yes";
        "veto files" = "/.DS_Store/.Spotlight-V100/.Trashes/.fseventsd/";
        "delete veto files" = "yes";
      };
    };
  };

  # Avahi: mDNS for macOS to discover Samba shares via Bonjour
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # ── btrbk ──────────────────────────────────────────────────────────────────
  # Daily snapshots + send/receive backup to /backup (sdc)
  services.btrbk.instances."backup" = {
    onCalendar = "daily";
    settings = {
      snapshot_preserve_min = "2d";
      snapshot_preserve     = "7d 4w";
      target_preserve_min   = "no";
      target_preserve       = "30d 10w 6m";

      volume."/data" = {
        snapshot_dir = "@snapshots";
        subvolume = {
          "@less".target   = "/backup";
          "@more".target   = "/backup";
          "@newlix".target = "/backup";
        };
      };
    };
  };

  # Mount backup disk only during btrbk, unmount after to keep HDD spun down
  systemd.services."btrbk-backup".serviceConfig = {
    ExecStartPre = "${pkgs.util-linux}/bin/mount /backup";
    ExecStartPost = "${pkgs.util-linux}/bin/umount /backup";
  };

  # ── SSH ────────────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  system.stateVersion = "25.05";
}
