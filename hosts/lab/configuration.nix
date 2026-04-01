{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ../../home/packages.nix ];
  # ── Boot ───────────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Keep last 5 NixOS generations in the boot menu
  boot.loader.systemd-boot.configurationLimit = 5;

  boot.kernelPackages = pkgs.linuxPackages;  # LTS — avoids NVIDIA driver build failures on kernel bumps

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
    ];
  };

  # ── Caps Lock → Ctrl+Space (keyd) ─────────────────────────────────────────
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        capslock = "C-space";
      };
    };
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
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  # NVIDIA RTX 5070 Ti (GB203/Blackwell)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;                 # Blackwell mandatory: proprietary module lacks GB2xx support

    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = false;
  };

  # ── CUDA ───────────────────────────────────────────────────────────────────
  hardware.nvidia-container-toolkit.enable = true;  # nvidia-container-runtime for Docker

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
    libx11
    libxcursor
    libxext
    libxfixes
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
        # Shared defaults for all shares
        "create mask"        = "0700";
        "directory mask"     = "0700";
        "ea support"         = "yes";
        "veto files"         = "/.DS_Store/.Spotlight-V100/.Trashes/.fseventsd/";
        "delete veto files"  = "yes";
      };
      data = {
        path = "/data";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "newlix";
      };
      newlix = {
        path = "/home/newlix";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "newlix";
      };
      "115" = {
        path = "/115";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "newlix";
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
    ExecStartPre = "-${pkgs.util-linux}/bin/mount /backup";
    # ExecStopPost runs regardless of success/failure; '-' tolerates already-unmounted
    ExecStopPost = "-${pkgs.util-linux}/bin/umount /backup";
  };

  # ── Steam ─────────────────────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # ── VNC (headless browser auth) ──────────────────────────────────────────
  # Added to systemPackages for x11vnc etc.
  environment.systemPackages = with pkgs; [
    xorg-server
    x11vnc
  ];

  # ── Niri (Wayland compositor) ──────────────────────────────────────────────
  programs.niri.enable = true;

  # greetd login manager — auto-launches niri
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
      user = "greeter";
    };
  };

  # ── Swaylock ──────────────────────────────────────────────────────────────
  security.pam.services.swaylock = {};

  # ── SSH ────────────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # ── Tailscale ─────────────────────────────────────────────────────────────
  services.tailscale.enable = true;

  # ── Eternal Terminal ─────────────────────────────────────────────────────
  services.eternal-terminal.enable = true;
  networking.firewall.allowedTCPPorts = [ 2022 ];

  system.stateVersion = "25.05";
}
