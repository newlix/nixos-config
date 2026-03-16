{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # niri.homeModules.config enables programs.niri.settings + config.lib.niri.actions
    # without re-installing the compositor (already handled by nixosModules.niri)
    #inputs.niri.homeModules.config
    inputs.noctalia.homeModules.default
  ];

  home.username = "newlix";
  home.homeDirectory = "/home/newlix";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Disable the KDE polkit agent started by niri-flake — Noctalia's Polkit plugin takes over
  systemd.user.services.polkit-kde-authentication-agent-1 = lib.mkForce {};

  # ── niri ───────────────────────────────────────────────────────────────────
  programs.niri.settings = {
    # Wayland / NVIDIA environment variables
    # Set here so they're present inside the niri session for all child processes
    environment = {
      NIXOS_OZONE_WL               = "1";    # Electron apps use Wayland
      MOZ_ENABLE_WAYLAND           = "1";    # Firefox
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      QT_QPA_PLATFORM              = "wayland";
      # NVIDIA EGL/VA-API — needed for hardware video decode and GL under niri
      LIBVA_DRIVER_NAME           = "nvidia";
      GBM_BACKEND                 = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME   = "nvidia";
      # Fcitx5 input method — XMODIFIERS covers XWayland apps;
      # GTK/QT vars cover apps that don't use the Wayland text-input protocol
      XMODIFIERS    = "@im=fcitx";
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE  = "fcitx";
      SDL_IM_MODULE = "fcitx";
    };

    input = {
      keyboard.xkb.layout = "us";
      mouse.accel-speed = 0.0;
    };

    layout = {
      gaps = 8;
      border = {
        enable = true;
        width = 2;
        active.color   = "#7fc8ff";
        inactive.color = "#404040";
      };
      focus-ring.enable = false;  # using border instead
    };

    # Autostart Noctalia on login
    spawn-at-startup = [
      { command = [ "noctalia-shell" ]; }
      # xwayland-satellite: bridges X11 apps to run under niri without a full Xwayland session
      { command = [ "xwayland-satellite" ]; }
    ];

  };

  # ── Noctalia ───────────────────────────────────────────────────────────────
  programs.noctalia-shell = {
    enable = true;
    plugins = {
      version = 2;
      sources = [
        {
          enabled = true;
          name = "Official Noctalia Plugins";
          url = "https://github.com/noctalia-dev/noctalia-plugins";
        }
      ];
      states = {
        mpd.enabled              = true;
        mpd.sourceUrl            = "https://github.com/noctalia-dev/noctalia-plugins";
        network-indicator.enabled   = true;
        network-indicator.sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        privacy-indicator.enabled   = true;
        privacy-indicator.sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        screen-recorder.enabled     = true;
        screen-recorder.sourceUrl   = "https://github.com/noctalia-dev/noctalia-plugins";
        mini-docker.enabled         = true;
        mini-docker.sourceUrl       = "https://github.com/noctalia-dev/noctalia-plugins";
        polkit-agent.enabled        = true;
        polkit-agent.sourceUrl      = "https://github.com/noctalia-dev/noctalia-plugins";
        clipper.enabled             = true;
        clipper.sourceUrl           = "https://github.com/noctalia-dev/noctalia-plugins";
      };
    };
  };

  # ── Git ────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user = {
        name  = "newlix";
        email = "newlix134@gmail.com";
      };
      init.defaultBranch = "main";
      credential."https://github.com".helper    = "!gh auth git-credential";
      credential."https://gist.github.com".helper = "!gh auth git-credential";
      filter.lfs = {
        process  = "git-lfs filter-process";
        required = true;
        clean    = "git-lfs clean -- %f";
        smudge   = "git-lfs smudge -- %f";
      };
    };
  };

  # ── Bash ───────────────────────────────────────────────────────────────────
  programs.bash = {
    enable = true;
    historySize     = 100000;
    historyFileSize = 200000;
    historyControl  = [ "ignoreboth" "erasedups" ];

    sessionVariables = {
      EDITOR   = "vi";
      MANPAGER = "less -X";
      GOPATH   = "$HOME/go";
    };

    shellAliases = {
      ls   = "eza";
      ll   = "eza -lah --icons";
      grep = "grep --color=auto";
      df   = "df -h";
      gca  = "git add . && git commit -a -m";
      gp   = "git push";
      gco  = "git checkout";
      gb   = "git branch";
      gs   = "git status";
      yt-dlp-audio = "yt-dlp -f 'bestaudio' -x --audio-format mp3";
      yt-dlp-video = "yt-dlp -S ext:mp4:m4a";
    };

    initExtra = ''
      shopt -s checkwinsize
      bind 'set completion-ignore-case on'
      bind 'set show-all-if-ambiguous on'
      bind 'TAB:menu-complete'

      # PATH extras
      export PATH="$HOME/core/sh:$HOME/bin:$GOPATH/bin:$PATH"

      # tmux session switcher
      tm() {
        local session
        session=$(tmux ls -F "#{session_name}" | fzf --exit-0) \
          && tmux attach -t "$session" \
          || tmux new-session
      }
    '';
  };

  # ── direnv ─────────────────────────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;  # faster nix flake eval + caching
  };

  # ── MPD ────────────────────────────────────────────────────────────────────
  services.mpd = {
    enable = true;
    musicDirectory = "/data/music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }
    '';
  };

  # ── tmux ───────────────────────────────────────────────────────────────────
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    historyLimit = 50000;
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;
  };

  # ── User packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    wofi
    gh       # GitHub CLI (used by git credential helper)
    claude-code
    git-lfs
    fzf
    vscode

    # Go
    gopls          # Go language server (VSCode / Sublime LSP)
    golangci-lint  # linter

    # Python
    uv             # Python package & project manager

    # Node.js
    fnm            # Node.js version manager (binaries work via nix-ld)

    # Noctalia required
    brightnessctl  # backlight brightness (also used by Noctalia keybinds)
    ddcutil        # DDC/CI brightness for external monitors (needs i2c group)
    imagemagick    # wallpaper resizing & template processing

    # Noctalia recommended
    wlsunset       # night light / colour temperature

    # Backup
    restic
    rclone

    mpv
    imv
    eza
    jq
    btop
    nh
    playerctl
    ncdu
    mpc
    xwayland-satellite
    superfile
    pkgs.thunar
    google-chrome
    sublime4
  ];
}
