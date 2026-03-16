{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # niri.homeModules.config enables programs.niri.settings + config.lib.niri.actions
    # without re-installing the compositor (already handled by nixosModules.niri)
    inputs.niri.homeModules.config
    inputs.noctalia.homeModules.default
  ];

  home.username = "newlix";
  home.homeDirectory = "/home/newlix";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Disable the KDE polkit agent started by niri-flake — Noctalia's Polkit plugin takes over
  systemd.user.services.polkit-kde-authentication-agent-1.enable = false;

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

    # ── Keybinds ─────────────────────────────────────────────────────────────
    # Uses config.lib.niri.actions for type-safe action definitions
    binds = with config.lib.niri.actions; {
      # Apps
      "Mod+Return".action = spawn "foot";
      "Mod+D".action      = spawn "wofi" "--show" "drun";
      "Mod+B".action      = spawn "zen";

      # Window management
      "Mod+Q".action            = close-window;
      "Mod+F".action            = fullscreen-window;
      "Mod+Shift+F".action      = toggle-window-floating;
      "Mod+Shift+Q".action      = quit;
      "Mod+Shift+Slash".action  = show-hotkey-overlay;

      # Focus (vim-style)
      "Mod+H".action = focus-column-left;
      "Mod+L".action = focus-column-right;
      "Mod+J".action = focus-window-down;
      "Mod+K".action = focus-window-up;

      # Move windows
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+L".action = move-column-right;
      "Mod+Shift+J".action = move-window-down;
      "Mod+Shift+K".action = move-window-up;

      # Resize columns
      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Equal".action = set-column-width "+10%";

      # Workspaces
      "Mod+1".action = focus-workspace 1;
      "Mod+2".action = focus-workspace 2;
      "Mod+3".action = focus-workspace 3;
      "Mod+4".action = focus-workspace 4;
      "Mod+5".action = focus-workspace 5;
      "Mod+Shift+1".action = move-column-to-workspace 1;
      "Mod+Shift+2".action = move-column-to-workspace 2;
      "Mod+Shift+3".action = move-column-to-workspace 3;
      "Mod+Shift+4".action = move-column-to-workspace 4;
      "Mod+Shift+5".action = move-column-to-workspace 5;

      # Screenshot (grim + slurp)
      "Print".action       = screenshot;
      "Shift+Print".action = screenshot-screen;
      "Alt+Print".action   = screenshot-window;

      # Volume (pipewire/wpctl)
      "XF86AudioRaiseVolume".action  = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+";
      "XF86AudioLowerVolume".action  = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-";
      "XF86AudioMute".action         = spawn "wpctl" "set-mute"   "@DEFAULT_AUDIO_SINK@" "toggle";
    };
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
    userName  = "newlix";
    userEmail = "newlix@me.com";
    extraConfig = {
      init.defaultBranch = "main";
      credential."https://github.com".helper    = "!/run/current-system/sw/bin/gh auth git-credential";
      credential."https://gist.github.com".helper = "!/run/current-system/sw/bin/gh auth git-credential";
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
      export PATH="$HOME/core/sh:$HOME/bin:$HOME/.local/bin:$GOPATH/bin:$HOME/ngc-cli:$PATH"

      # fnm (Node.js version manager — not yet managed by Nix)
      FNM_PATH="$HOME/.local/share/fnm"
      if [ -d "$FNM_PATH" ]; then
        export PATH="$FNM_PATH:$PATH"
        eval "$(fnm env)"
      fi

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
    git-lfs
    fzf
    vscode

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
    swaylock
    jq
    btop
    nh
    nvtop
    playerctl
    ncdu
    mpc-cli
    xwayland-satellite
    superfile
    xfce.thunar
    google-chrome
    sublime4
  ];
}
