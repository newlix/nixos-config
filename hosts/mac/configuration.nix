{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ../../home/packages.nix ];
  # ── Nix settings ───────────────────────────────────────────────────────────
  # Determinate Nix manages the daemon; let it handle nix.conf
  nix.enable = false;

  # ── Nix GC (weekly, keep 14 days) ──────────────────────────────────────────
  launchd.daemons.nix-gc = {
    command = "/nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-older-than 14d";
    serviceConfig = {
      RunAtLoad = false;
      StartCalendarInterval = [{ Weekday = 0; Hour = 3; Minute = 0; }];
    };
  };

  # Allow unfree packages (e.g. some fonts, tools)
  nixpkgs.config.allowUnfree = true;

  # ── Mac-only system packages ───────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    docker-client
    eternal-terminal
    mas
    swiftformat
  ];

  # ── macOS defaults ─────────────────────────────────────────────────────────
  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv";
    };
    NSGlobalDomain = {
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
  };

  # ── Homebrew ────────────────────────────────────────────────────────────────
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";  # remove formulae/casks not listed here
    };

    masApps = {
      LINE = 539883307;
      "The Unarchiver" = 425424353;
      Xcode = 497799835;
    };

    taps = [
      "peripheryapp/periphery"
    ];

    brews = [
      "periphery"
    ];

    casks = [
      "android-studio"
      "antigravity"
      "appcleaner"
      "arq"
      "balenaetcher"
      "flashspace"
      "google-chrome"
      "iina"
      "kobo"
      "istat-menus"
      "openemu"
      "postico"
      "sublime-text"
      "telegram"
      "transmit"
      "utm"
      "vnc-viewer"
      "zed"
      "zen"
    ];
  };

  # ── Users ──────────────────────────────────────────────────────────────────
  system.primaryUser = "newlix";
  users.users.newlix = {
    home = "/Users/newlix";
  };

  # ── Security ───────────────────────────────────────────────────────────────
  security.pam.services.sudo_local.touchIdAuth = true;

  # ── Home Manager ───────────────────────────────────────────────────────────
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs; };
    users.newlix = import ./home.nix;
  };

  # Used for backwards compatibility
  system.stateVersion = 6;
}
