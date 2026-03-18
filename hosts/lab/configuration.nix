{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ../../home/packages.nix ];
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

  # ── Graphics ───────────────────────────────────────────────────────────────
  hardware.graphics.enable = true;

  nixpkgs.config.allowUnfree = true;

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
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
    mesa
    libgbm
    expat
    alsa-lib
    at-spi2-atk
    at-spi2-core
    libxkbcommon
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

  # ── Tailscale ─────────────────────────────────────────────────────────────
  services.tailscale.enable = true;

  # ── Eternal Terminal ─────────────────────────────────────────────────────
  services.eternal-terminal.enable = true;
  networking.firewall.allowedTCPPorts = [ 2022 ];

  system.stateVersion = "25.05";
}
