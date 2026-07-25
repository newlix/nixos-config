{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ../../home/common.nix ];

  home.username = "newlix";
  home.homeDirectory = "/home/newlix";
  home.stateVersion = "25.05";

  # Lab-specific packages (NVIDIA GPU available)
  home.packages = with pkgs; [
    ffmpeg
    imv
    swaynotificationcenter
    (writeShellScriptBin "extract-here" ''
      term() {
        foot -e sh -c '"$@"; echo; read -p "按 Enter 關閉..."' extract-here "$@"
      }

      try_extract() {
        case "$1" in
          *.zip|*.ZIP)
            unzip -o "$1" </dev/null 2>/dev/null && return 0
            term unzip -o "$1"
            ;;
          *.rar|*.RAR)
            unrar x "$1" </dev/null 2>/dev/null && return 0
            term unrar x "$1"
            ;;
          *.7z)
            7z x "$1" </dev/null 2>/dev/null && return 0
            term 7z x "$1"
            ;;
          *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz|*.tar.zst)
            tar -xf "$1"
            ;;
          *.gz)
            gunzip "$1"
            ;;
          *.bz2)
            bunzip2 "$1"
            ;;
          *.xz)
            unxz "$1"
            ;;
          *.zst)
            unzstd "$1"
            ;;
        esac
      }

      for f in "$@"; do
        dir=$(dirname "$f")
        cd "$dir" || continue
        try_extract "$f"
      done
    '')
    (writeShellScriptBin "zed-open" ''
      # Opens file(s) in Zed, then focuses existing window via Niri IPC
      zeditor "$@"
      sleep 0.3
      wid=$(niri msg windows 2>/dev/null | awk '/^Window ID [0-9]+:$/ {id=$3} /App ID: "dev.zed.Zed"/ {gsub(/:/,"",id); print id; exit}')
      if [ -n "$wid" ]; then
        niri msg action focus-window --id "$wid" 2>/dev/null || true
      fi
    '')
  ];

  programs.bash.shellAliases = {
    open = "nautilus";
  };

  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      thumbfast
      autoload
      mpris
    ];
    bindings = {
      "Ctrl+LEFT" = "playlist-prev";
      "Ctrl+RIGHT" = "playlist-next";
    };
    config = {
      osc = "yes";
      osd-bar = "no";
      border = "no";
      keepaspect-window = "no";
      volume = 30;
      save-position-on-quit = "yes";
      hwdec = "auto-safe";
      vo = "gpu";
      gpu-api = "opengl";
    };
  };

  # ── Niri Configuration (KDL) ──────────────────────────────────────────────
  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            numlock
        }
        touchpad {
            tap
            natural-scroll
        }
        mouse {
            natural-scroll
        }
    }

    gestures {
        hot-corners {
            off
        }
    }

    layout {
        gaps 8
        center-focused-column "never"
        preset-column-widths {
            proportion 0.5
        }
        default-column-width { proportion 0.5; }
        focus-ring {
            width 1
            active-color "#3a3a3c"
            inactive-color "#2c2c2e"
        }
        shadow {
            on
            softness 30
            spread 5
            offset x=0 y=5
            color "#0007"
        }
    }

    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "swaync"

    prefer-no-csd
    screenshot-path "~/Downloads/Screenshot from %Y-%m-%d %H-%M-%S.png"

    // Render compositor on AMD iGPU, keep NVIDIA VRAM free for compute/gaming
    debug {
        render-drm-device "/dev/dri/by-path/pci-0000:0d:00.0-render"
    }

    window-rule {
        match app-id=r#"^org\.wezfurlong\.wezterm$"#
        default-column-width {}
    }
    window-rule {
        match app-id=r#"firefox$"# title="^Picture-in-Picture$"
        open-floating true
    }
    window-rule {
        match app-id="dev.zed.Zed"
        open-focused true
    }
    window-rule {
        geometry-corner-radius 8
        clip-to-geometry true
    }

    binds {
        Mod+Shift+Slash { show-hotkey-overlay; }
        Mod+T { spawn "foot"; }
        Mod+E { spawn "nautilus" "--new-window"; }
        Mod+B { spawn "google-chrome-stable" "--new-window"; }
        Mod+G { spawn "google-chrome-stable" "--app=https://gemini.google.com"; }
        Super+Space { spawn "fuzzel"; }
        Mod+N { spawn "swaync-client" "-t" "-sw"; }
        Ctrl+Mod+Q { spawn "wlogout" "-b" "4" "-T" "480" "-B" "480" "-L" "300" "-R" "300"; }

        XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
        XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
        XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

        XF86AudioPlay        allow-when-locked=true { spawn-sh "playerctl play-pause"; }
        XF86AudioStop        allow-when-locked=true { spawn-sh "playerctl stop"; }
        XF86AudioPrev        allow-when-locked=true { spawn-sh "playerctl previous"; }
        XF86AudioNext        allow-when-locked=true { spawn-sh "playerctl next"; }

        XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }

        Mod+O { toggle-overview; }
        Ctrl+Q { close-window; }

        Mod+Left  { focus-column-left; }

        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }
        Mod+Right { focus-column-right; }
        Mod+Ctrl+Left  { move-column-left; }
        Mod+Ctrl+Down  { move-window-down; }
        Mod+Ctrl+Up    { move-window-up; }
        Mod+Ctrl+Right { move-column-right; }

        Mod+Home { focus-column-first; }
        Mod+End  { focus-column-last; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }

        Mod+Ctrl+1 { move-column-to-workspace 1; }
        Mod+Ctrl+2 { move-column-to-workspace 2; }
        Mod+Ctrl+3 { move-column-to-workspace 3; }
        Mod+Ctrl+4 { move-column-to-workspace 4; }
        Mod+Ctrl+5 { move-column-to-workspace 5; }
        Mod+Ctrl+6 { move-column-to-workspace 6; }
        Mod+Ctrl+7 { move-column-to-workspace 7; }
        Mod+Ctrl+8 { move-column-to-workspace 8; }
        Mod+Ctrl+9 { move-column-to-workspace 9; }

        Mod+R { switch-preset-column-width; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }

        // Mod+Minus { set-column-width "-10%"; }
        // Mod+Equal { set-column-width "+10%"; }
        // Mod+Shift+Minus { set-window-height "-10%"; }
        // Mod+Shift+Equal { set-window-height "+10%"; }

        Ctrl+Shift+3 { screenshot-screen; }
        Ctrl+Shift+4 { screenshot; }
        Ctrl+Shift+5 { screenshot-window; }

        Ctrl+Shift+Q { quit; }
    }
  '';

  # ── waybar ─────────────────────────────────────────────────────────────────
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [{
      layer = "top";
      position = "top";
      exclusive = true;
      height = 26;
      spacing = 0;

      modules-left = [
        "custom/lock"
        "niri/workspaces"
      ];

      modules-center = [
        "niri/window"
      ];

      modules-right = [
        "custom/sysinfo"
        "custom/netspeed"
        "wireplumber"
        "clock"
        "custom/notification"
      ];

      "niri/window" = {
        format = "{}";
        max-length = 50;
        separate-outputs = true;
      };

      "niri/workspaces" = {
        format = "{value}";
      };

      "custom/sysinfo" = {
        interval = 5;
        exec = "echo \"CPU $(awk '{u=$2+$4; t=$2+$4+$5; if(NR>1) printf \"%.0f\", (u-ou)/(t-ot)*100; ou=u; ot=t}' <(grep '^cpu ' /proc/stat) <(sleep 0.5; grep '^cpu ' /proc/stat))%  RAM $(free | awk '/Mem/{printf \"%.0f\", $3/$2*100}')%  $(( $(cat $(dirname $(grep -rl k10temp /sys/class/hwmon/*/name 2>/dev/null | head -1))/temp1_input 2>/dev/null || echo 0) / 1000 ))°C\"";
        tooltip = false;
        on-click = "foot -e btop";
      };

      "custom/netspeed" = {
        interval = 5;
        exec = "iface=$(ip route show default | awk '/default/{print $5; exit}'); rx0=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null); tx0=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null); sleep 1; rx1=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null); tx1=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null); rxs=$(( (rx1-rx0) )); txs=$(( (tx1-tx0) )); if [ $rxs -gt 1048576 ]; then rxf=$(printf '%5.1fM' $(echo \"scale=1; $rxs/1048576\" | bc)); elif [ $rxs -gt 1024 ]; then rxf=$(printf '%5dK' $(($rxs/1024))); else rxf=$(printf '%5dB' $rxs); fi; if [ $txs -gt 1048576 ]; then txf=$(printf '%5.1fM' $(echo \"scale=1; $txs/1048576\" | bc)); elif [ $txs -gt 1024 ]; then txf=$(printf '%5dK' $(($txs/1024))); else txf=$(printf '%5dB' $txs); fi; echo \"▼$rxf ▲$txf\"";
        on-click = "foot -e sudo ${pkgs.bandwhich}/bin/bandwhich";
        tooltip = false;
      };

      "custom/notification" = {
        tooltip = true;
        format = "<span size='14pt'>{icon}</span>";
        format-icons = {
          notification = "";
          none = "";
          dnd-notification = "";
          dnd-none = "";
          inhibited-notification = "";
          inhibited-none = "";
          dnd-inhibited-notification = "";
          dnd-inhibited-none = "";
        };
        return-type = "json";
        exec-if = "which swaync-client";
        exec = "swaync-client -swb";
        on-click = "swaync-client -t -sw";
        on-click-right = "swaync-client -d -sw";
        escape = true;
      };

      "clock" = {
        format = "{:%a %b %d %I:%M %p}";
        tooltip-format = "<big>{:%Y %B}</big>\\n<tt><small>{calendar}</small></tt>";
        interval = 60;
        on-click = "google-chrome-stable --app=https://calendar.google.com";
      };

      "wireplumber" = {
        scroll-step = 5;
        format = "VOL {volume}%";
        format-muted = "MUTE";
        on-click = "pavucontrol";
        on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "format-source" = "";
        "format-source-muted" = "";
      };

      "custom/lock" = {
        format = "⏻";
        tooltip = false;
        on-click = "pgrep -x wlogout > /dev/null && pkill wlogout || wlogout -b 4 -T 480 -B 480 -L 300 -R 300";
      };
    }];

    style = ''
      * {
        font-family: 'Hack', 'Symbols Nerd Font', monospace;
        font-size: 13px;
        min-height: 0;
      }

      #waybar {
        background-color: rgba(30, 30, 30, 0.9);
        color: rgba(255, 255, 255, 0.85);
        padding: 0;
      }

      /* Workspaces Styles */
      #workspaces {
        margin: 0 4px;
      }
      #workspaces button {
        padding: 0 10px;
        margin: 4px 2px;
        color: rgba(255, 255, 255, 0.55);
        border-radius: 6px;
        border: none;
        transition: all 0.2s ease;
      }
      #workspaces button.active {
        color: rgba(255, 255, 255, 0.95);
        background-color: rgba(255, 255, 255, 0.12);
      }
      #workspaces button:hover {
        background-color: rgba(255, 255, 255, 0.08);
        color: rgba(255, 255, 255, 0.85);
      }
      #workspaces button.urgent {
        color: #ff6c60;
      }

      /* All modules */
      #custom-lock,
      #custom-sysinfo,
      #custom-netspeed,
      #custom-notification,
      #clock,
      #wireplumber {
        padding: 4px 12px;
        color: rgba(255, 255, 255, 0.85);
        transition: background-color 0.15s ease;
      }

      /* Hover */
      #custom-lock:hover,
      #custom-sysinfo:hover,
      #custom-netspeed:hover,
      #custom-notification:hover,
      #clock:hover,
      #wireplumber:hover {
        background-color: rgba(255, 255, 255, 0.08);
      }

      /* Left-most module */
      #custom-lock {
        padding-left: 16px;
      }

      /* Right-most module */
      #clock {
        padding-right: 16px;
      }

      /* Dimmed modules */
      #custom-sysinfo,
      #custom-netspeed,
      #wireplumber {
        color: rgba(255, 255, 255, 0.55);
      }

      /* Tooltip */
      tooltip {
        background-color: rgba(40, 40, 40, 0.95);
        color: rgba(255, 255, 255, 0.9);
        padding: 6px 12px;
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 8px;
        font-size: 12px;
      }
    '';
  };

  # ── wlogout (power menu) ────────────────────────────────────────────────────
  programs.wlogout = {
    enable = true;
    layout = [
      { label = "lock";     action = "swaylock & niri msg action power-off-monitors"; text = ""; keybind = "l"; }
      { label = "logout";   action = "niri msg action quit --skip-confirmation"; text = ""; keybind = "e"; }
      { label = "reboot";   action = "systemctl reboot";   text = "";  keybind = "r"; }
      { label = "shutdown"; action = "systemctl poweroff"; text = "";  keybind = "p"; }
    ];
    style = ''
      * {
        box-shadow: none;
      }

      window {
        background-color: rgba(20, 20, 22, 0.6);
      }

      button {
        color: #ffffff;
        background-color: rgba(255, 255, 255, 0.05);
        border: 1px solid rgba(255, 255, 255, 0.10);
        border-radius: 20px;
        margin: 12px;
        background-repeat: no-repeat;
        background-position: center;
        background-size: 32%;
        transition: background-color 0.15s ease, border-color 0.15s ease;
      }

      button:hover,
      button:active {
        background-color: rgba(255, 255, 255, 0.14);
        border-color: rgba(255, 255, 255, 0.28);
        outline: none;
      }

      #lock         { background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png")); }
      #logout       { background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png")); }
      #reboot   { background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png")); }
      #shutdown { background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png")); }
    '';
  };

  # ── foot ───────────────────────────────────────────────────────────────────
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "Hack:size=16";
        pad = "16x16";
        "underline-offset" = "4px";
        "selection-target" = "none";
      };
      mouse = {
        hide-when-typing = "yes";
      };
      mouse-bindings = {
        select-extend = "none";
        primary-paste = "none";
      };
      # Mac 風格快捷鍵：keyd 把實體 Cmd 映射為 Ctrl，
      # 這裡讓 foot 用 Ctrl+key 觸發對應動作。
      # clipboard-copy 有選取時複製，無選取時 passthrough（送 SIGINT）
      key-bindings = {
        clipboard-copy = "Control+Shift+c";
        clipboard-paste = "Control+Shift+v Control+v";
        search-start = "Control+Shift+r Control+f";
        spawn-terminal = "Control+Shift+n Control+n";
      };
      "colors-dark" = {
        background = "000000";
        foreground = "f6f3e8";
        regular0 = "4e4e4e";
        regular1 = "ff6c60";
        regular2 = "a8ff60";
        regular3 = "ffffb6";
        regular4 = "96cbfe";
        regular5 = "ff73fd";
        regular6 = "c6c5fe";
        regular7 = "eeeeee";
        bright0 = "7c7c7c";
        bright1 = "ffb6b0";
        bright2 = "ceffab";
        bright3 = "ffffcb";
        bright4 = "b5dcfe";
        bright5 = "ff9cfe";
        bright6 = "dfdffe";
        bright7 = "ffffff";
      };
    };
  };


  # ── ffmpegthumbnailer (Borderless & High Quality) ────────────────────────
  # Nautilus runs thumbnailers inside a bwrap sandbox that only exposes
  # /nix/store, so the Exec path must be an absolute store path. MimeType
  # must be a superset of the package's bundled .thumbnailer so this
  # override wins for every video type — otherwise the system entry runs
  # with -f and adds the filmstrip border.
  xdg.dataFile."thumbnailers/ffmpegthumbnailer.thumbnailer".text = ''
    [Thumbnailer Entry]
    TryExec=${pkgs.ffmpegthumbnailer}/bin/ffmpegthumbnailer
    Exec=${pkgs.ffmpegthumbnailer}/bin/ffmpegthumbnailer -i %i -o %o -s %s -q 10
    MimeType=video/3gpp;video/3gpp2;video/annodex;video/dv;video/isivideo;video/jpeg;video/mj2;video/mp2t;video/mp4;video/mpeg;video/ogg;video/quicktime;video/unknown;video/vnd.avi;video/vnd.mpegurl;video/vnd.radgamettools.bink;video/vnd.radgamettools.smacker;video/vnd.rn-realvideo;video/vnd.vivo;video/vnd.youtube.yt;video/wavelet;video/webm;video/x-anim;video/x-flic;video/x-flv;video/x-javafx;video/x-m4v;video/x-matroska;video/x-matroska-3d;video/x-mjpeg;video/x-mng;video/x-ms-asf;video/x-ms-wmv;video/x-msvideo;video/x-nsv;video/x-ogm+ogg;video/x-sgi-movie;video/x-theora+ogg;application/mxf;application/vnd.ms-asf;application/vnd.rn-realmedia;application/x-matroska;application/ogg;
  '';

  # Nautilus default thumbnail-limit is ~10 MB, which silently skips most
  # videos. Lift the cap and force thumbnails for local files.
  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      show-image-thumbnails = "always";
      thumbnail-limit = lib.hm.gvariant.mkUint64 4096;
    };
  };

  # ── XDG MIME Apps ────────────────────────────────────────────────────────
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = [ "zed.desktop" ];
      "text/markdown" = [ "zed.desktop" ];
      "application/x-zerosize" = [ "zed.desktop" ]; # Empty files
      "application/x-shellscript" = [ "zed.desktop" ];
      "text/x-python" = [ "zed.desktop" ];
      "text/x-go" = [ "zed.desktop" ];
      "text/x-nix" = [ "zed.desktop" ];
      "application/json" = [ "zed.desktop" ];

      # Web → Chrome
      "text/html" = [ "google-chrome.desktop" ];
      "application/xhtml+xml" = [ "google-chrome.desktop" ];
      "x-scheme-handler/http" = [ "google-chrome.desktop" ];
      "x-scheme-handler/https" = [ "google-chrome.desktop" ];
      "x-scheme-handler/about" = [ "google-chrome.desktop" ];
      "x-scheme-handler/unknown" = [ "google-chrome.desktop" ];

      # Audio → mpv
      "audio/mpeg" = [ "mpv.desktop" ];
      "audio/flac" = [ "mpv.desktop" ];
      "audio/x-flac" = [ "mpv.desktop" ];
      "audio/ogg" = [ "mpv.desktop" ];
      "audio/x-vorbis+ogg" = [ "mpv.desktop" ];
      "audio/opus" = [ "mpv.desktop" ];
      "audio/aac" = [ "mpv.desktop" ];
      "audio/mp4" = [ "mpv.desktop" ];
      "audio/x-m4a" = [ "mpv.desktop" ];
      "audio/wav" = [ "mpv.desktop" ];
      "audio/x-wav" = [ "mpv.desktop" ];
      "audio/x-ms-wma" = [ "mpv.desktop" ];

      # Images → imv-dir
      "image/jpeg" = [ "imv-dir.desktop" ];
      "image/png" = [ "imv-dir.desktop" ];
      "image/gif" = [ "imv-dir.desktop" ];
      "image/webp" = [ "imv-dir.desktop" ];
      "image/bmp" = [ "imv-dir.desktop" ];
      "image/tiff" = [ "imv-dir.desktop" ];
      "image/svg+xml" = [ "imv-dir.desktop" ];
      "image/heif" = [ "imv-dir.desktop" ];
      "image/heic" = [ "imv-dir.desktop" ];
      "image/avif" = [ "imv-dir.desktop" ];
      "image/x-portable-pixmap" = [ "imv-dir.desktop" ];
      "image/x-portable-graymap" = [ "imv-dir.desktop" ];
      "image/x-portable-bitmap" = [ "imv-dir.desktop" ];

      # Archives → Extract Here
      "application/zip" = [ "extract-here.desktop" ];
      "application/x-zip-compressed" = [ "extract-here.desktop" ];
      "application/x-tar" = [ "extract-here.desktop" ];
      "application/gzip" = [ "extract-here.desktop" ];
      "application/x-bzip" = [ "extract-here.desktop" ];
      "application/x-bzip2" = [ "extract-here.desktop" ];
      "application/x-xz" = [ "extract-here.desktop" ];
      "application/x-7z-compressed" = [ "extract-here.desktop" ];
      "application/x-rar" = [ "extract-here.desktop" ];
      "application/vnd.rar" = [ "extract-here.desktop" ];
      "application/x-zstd" = [ "extract-here.desktop" ];
      "application/x-compress" = [ "extract-here.desktop" ];
      "application/x-lz4" = [ "extract-here.desktop" ];
      "application/x-lzip" = [ "extract-here.desktop" ];
    };
  };

  # ── Fuzzel ──────────────────────────────────────────────────────────────
  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    [main]
    font=Hack:size=13
    icon-theme=Papirus-Dark
    icons-enabled=yes
    lines=8
    width=35
    horizontal-pad=16
    vertical-pad=12
    inner-pad=8

    [colors]
    background=1e1e1eee
    text=ffffffd9
    match=8ab4f8ff
    selection=ffffff1f
    selection-text=ffffffff
    selection-match=8ab4f8ff
    border=ffffff14
    prompt=ffffff8c
  '';

  # ── Desktop Entries ─────────────────────────────────────────────────────
  xdg.desktopEntries.steam = {
    name = "Steam";
    comment = "Application for managing and playing games on Steam";
    exec = "steam %U";
    icon = "steam";
    categories = [ "Game" "Network" "FileTransfer" ];
    terminal = false;
    mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
    settings = {
      Path = "/home/newlix";
      PrefersNonDefaultGPU = "true";
      X-KDE-RunOnDiscreteGpu = "true";
      StartupWMClass = "steam";
    };
  };

  xdg.desktopEntries.min = {
    name = "Min";
    comment = "A minimal, smarter web browser";
    exec = "min %U";
    icon = "min";
    categories = [ "Network" "WebBrowser" ];
    terminal = false;
    mimeType = [ "text/html" "text/xml" "x-scheme-handler/http" "x-scheme-handler/https" ];
  };

  xdg.desktopEntries.extract-here = {
    name = "Extract Here";
    exec = "extract-here %F";
    icon = "file-roller";
    categories = [ "Utility" "Archiving" ];
    terminal = false;
    mimeType = [
      "application/zip" "application/x-zip-compressed"
      "application/x-tar" "application/gzip" "application/x-bzip" "application/x-bzip2"
      "application/x-xz" "application/x-7z-compressed" "application/x-rar" "application/vnd.rar"
      "application/x-zstd" "application/x-compress" "application/x-lz4" "application/x-lzip"
    ];
  };

  xdg.desktopEntries.zed = {
    name = "Zed";
    exec = "zed-open %F";
    icon = "zed";
    categories = [ "Development" "TextEditor" ];
    terminal = false;
    mimeType = [ "text/plain" "text/markdown" "application/json" ];
  };

  programs.zed-editor = {
    enable = true;

    userSettings = {
      base_keymap = "SublimeText";
      ui_font_size = 16;
      buffer_font_size = 15;
      buffer_font_family = "Hack";
      theme = {
        mode = "system";
        light = "IR Black";
        dark = "IR Black";
      };
      autosave = "on_focus_change";
      scrollbar.show = "never";
      ui_font_family = "Hack";
      format_on_save = "on";
      terminal = {
        font_family = "Hack";
        font_size = 14;
      };
    };

    themes.ir-black = {
    "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";
    name = "IR Black";
    author = "Todd Werth";
    themes = [{
      name = "IR Black";
      appearance = "dark";
      style = {
        background = "#000000ff";
        "editor.background" = "#000000ff";
        "editor.foreground" = "#f6f3e8ff";
        "editor.gutter.background" = "#000000ff";
        "editor.line_number" = "#7c7c7cff";
        "editor.active_line_number" = "#f6f3e8ff";
        "editor.active_line.background" = "#1a1a1aff";
        "editor.wrap_guide" = "#2a2a2aff";
        "editor.indent_guide" = "#2a2a2aff";
        "editor.indent_guide_active" = "#4e4e4eff";
        border = "#333333ff";
        "border.variant" = "#222222ff";
        "border.focused" = "#96cbfeff";
        "border.selected" = "#96cbfeff";
        "border.transparent" = "#00000000";
        "border.disabled" = "#333333ff";
        "elevated_surface.background" = "#1a1a1aff";
        "surface.background" = "#111111ff";
        "element.background" = "#1a1a1aff";
        "element.hover" = "#2a2a2aff";
        "element.active" = "#333333ff";
        "element.selected" = "#333333ff";
        "element.disabled" = "#1a1a1aff";
        "ghost_element.background" = "#00000000";
        "ghost_element.hover" = "#2a2a2aff";
        "ghost_element.active" = "#333333ff";
        "ghost_element.selected" = "#333333ff";
        "ghost_element.disabled" = "#1a1a1aff";
        text = "#f6f3e8ff";
        "text.muted" = "#7c7c7cff";
        "text.placeholder" = "#4e4e4eff";
        "text.disabled" = "#4e4e4eff";
        "text.accent" = "#96cbfeff";
        icon = "#f6f3e8ff";
        "icon.muted" = "#7c7c7cff";
        "icon.disabled" = "#4e4e4eff";
        "icon.placeholder" = "#4e4e4eff";
        "icon.accent" = "#96cbfeff";
        "status_bar.background" = "#0a0a0aff";
        "title_bar.background" = "#0a0a0aff";
        "title_bar.inactive_background" = "#050505ff";
        "toolbar.background" = "#000000ff";
        "tab_bar.background" = "#0a0a0aff";
        "tab.active_background" = "#1a1a1aff";
        "tab.inactive_background" = "#0a0a0aff";
        "search.match_background" = "#ffffb640";
        "panel.background" = "#0a0a0aff";
        "panel.focused_border" = "#96cbfeff";
        "pane.focused_border" = "#96cbfeff";
        "scrollbar.thumb.background" = "#333333aa";
        "scrollbar.thumb.hover_background" = "#555555aa";
        "scrollbar.thumb.border" = "#00000000";
        "scrollbar.track.background" = "#00000000";
        "scrollbar.track.border" = "#00000000";
        "link_text.hover" = "#96cbfeff";
        conflict = "#ff6c60ff";
        "conflict.background" = "#ff6c6020";
        "conflict.border" = "#ff6c60ff";
        created = "#a8ff60ff";
        "created.background" = "#a8ff6020";
        "created.border" = "#a8ff60ff";
        deleted = "#ff6c60ff";
        "deleted.background" = "#ff6c6020";
        "deleted.border" = "#ff6c60ff";
        error = "#ff6c60ff";
        "error.background" = "#ff6c6020";
        "error.border" = "#ff6c60ff";
        hidden = "#4e4e4eff";
        "hidden.background" = "#0a0a0aff";
        "hidden.border" = "#333333ff";
        hint = "#7c7c7cff";
        "hint.background" = "#0a0a0aff";
        "hint.border" = "#333333ff";
        ignored = "#4e4e4eff";
        "ignored.background" = "#0a0a0aff";
        "ignored.border" = "#333333ff";
        info = "#96cbfeff";
        "info.background" = "#96cbfe20";
        "info.border" = "#96cbfeff";
        modified = "#ffffb6ff";
        "modified.background" = "#ffffb620";
        "modified.border" = "#ffffb6ff";
        predictive = "#4e4e4eff";
        "predictive.background" = "#0a0a0aff";
        "predictive.border" = "#333333ff";
        renamed = "#96cbfeff";
        "renamed.background" = "#96cbfe20";
        "renamed.border" = "#96cbfeff";
        success = "#a8ff60ff";
        "success.background" = "#a8ff6020";
        "success.border" = "#a8ff60ff";
        unreachable = "#4e4e4eff";
        "unreachable.background" = "#0a0a0aff";
        "unreachable.border" = "#333333ff";
        warning = "#ffffb6ff";
        "warning.background" = "#ffffb620";
        "warning.border" = "#ffffb6ff";
        "terminal.background" = "#000000ff";
        "terminal.foreground" = "#f6f3e8ff";
        "terminal.bright_foreground" = "#ffffffff";
        "terminal.dim_foreground" = "#7c7c7cff";
        "terminal.ansi.black" = "#4e4e4eff";
        "terminal.ansi.red" = "#ff6c60ff";
        "terminal.ansi.green" = "#a8ff60ff";
        "terminal.ansi.yellow" = "#ffffb6ff";
        "terminal.ansi.blue" = "#96cbfeff";
        "terminal.ansi.magenta" = "#ff73fdff";
        "terminal.ansi.cyan" = "#c6c5feff";
        "terminal.ansi.white" = "#eeeeeeff";
        "terminal.ansi.bright_black" = "#7c7c7cff";
        "terminal.ansi.bright_red" = "#ffb6b0ff";
        "terminal.ansi.bright_green" = "#ceffabff";
        "terminal.ansi.bright_yellow" = "#ffffcbff";
        "terminal.ansi.bright_blue" = "#b5dcfeff";
        "terminal.ansi.bright_magenta" = "#ff9cfeff";
        "terminal.ansi.bright_cyan" = "#dfdffeff";
        "terminal.ansi.bright_white" = "#ffffffff";
        players = [
          { cursor = "#f6f3e8ff"; background = "#96cbfeff"; selection = "#96cbfe40"; }
          { cursor = "#a8ff60ff"; background = "#a8ff60ff"; selection = "#a8ff6040"; }
          { cursor = "#ff73fdff"; background = "#ff73fdff"; selection = "#ff73fd40"; }
          { cursor = "#ffffb6ff"; background = "#ffffb6ff"; selection = "#ffffb640"; }
        ];
        syntax = {
          comment  = { color = "#7c7c7cff"; font_style = "italic"; };
          string   = { color = "#a8ff60ff"; };
          number   = { color = "#ff73fdff"; };
          keyword  = { color = "#96cbfeff"; };
          function = { color = "#ffffb6ff"; };
          type     = { color = "#ffffb6ff"; };
          variable = { color = "#f6f3e8ff"; };
          constant = { color = "#ff6c60ff"; };
          operator = { color = "#f6f3e8ff"; };
          property = { color = "#c6c5feff"; };
          attribute = { color = "#96cbfeff"; };
          tag      = { color = "#96cbfeff"; };
          label    = { color = "#ffffb6ff"; };
          punctuation = { color = "#f6f3e8ff"; };
          "punctuation.bracket" = { color = "#f6f3e8ff"; };
          "punctuation.delimiter" = { color = "#f6f3e8ff"; };
          "punctuation.special" = { color = "#ff73fdff"; };
          "string.escape" = { color = "#ff73fdff"; };
          "string.special" = { color = "#ff73fdff"; };
          "string.regex" = { color = "#ff73fdff"; };
          "variable.special" = { color = "#ff6c60ff"; };
          "keyword.operator" = { color = "#f6f3e8ff"; };
          boolean = { color = "#ff6c60ff"; };
          "comment.doc" = { color = "#7c7c7cff"; font_style = "italic"; };
          emphasis = { font_style = "italic"; };
          "emphasis.strong" = { font_weight = 700; };
          title = { color = "#ffffb6ff"; font_weight = 700; };
          link_text = { color = "#96cbfeff"; };
          link_uri = { color = "#a8ff60ff"; };
        };
      };
    }];
    };
  };

  # ── Fcitx5 (McBopomofo) ────────────────────────────────────────────────────
  # System-level i18n.inputMethod is in configuration.nix; only user config here.
  xdg.configFile."fcitx5/config".text = ''
    [Hotkey]
    EnumerateWithTriggerKeys=False
    [Hotkey/TriggerKeys]
    0=Control+space
    [Hotkey/EnumerateForwardKeys]
    0=
    [Behavior]
    PreeditEnabledByDefault=True
    ShareInputState=No
    DefaultPageSize=5
  '';
  # Despite the symlink from dotfiles/link.sh, home-manager's xdg.configFile
  # takes precedence because it's written last. fcitx5 may still overwrite this
  # on runtime, but at least the initial state is correct.
  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    # Group Name
    Name=Default
    # Layout
    Default Layout=us
    # Default Input Method
    DefaultIM=keyboard-us

    [Groups/0/Items/0]
    # Name
    Name=keyboard-us
    # Layout
    Layout=

    [Groups/0/Items/1]
    # Name
    Name=mcbopomofo
    # Layout
    Layout=

    [GroupOrder]
    0=Default
  '';

  # ── USB automount ────────────────────────────────────────────────────────
  services.udiskie.enable = true;

  # ── Notifications (swaync) ───────────────────────────────────────────────
  services.mako.enable = false;

  xdg.configFile."swaync/config.json".text = ''
    {
      "positionX": "right",
      "positionY": "top",
      "layer": "overlay",
      "control-center-layer": "top",
      "layer-shell": true,
      "cssPriority": "application",
      "control-center-margin-top": 8,
      "control-center-margin-bottom": 8,
      "control-center-margin-right": 8,
      "control-center-margin-left": 8,
      "notification-icon-size": 48,
      "notification-body-image-height": 160,
      "notification-body-image-width": 200,
      "timeout": 5,
      "timeout-low": 5,
      "timeout-critical": 0,
      "fit-to-screen": true,
      "control-center-width": 400,
      "control-center-height": 600,
      "notification-window-width": 350,
      "keyboard-shortcuts": true,
      "image-visibility": "when-available",
      "hide-on-clear-all": false,
      "hide-on-action": true,
      "script-fail-notify": true,
      "widgets": [
        "title",
        "dnd",
        "notifications",
        "mpris",
        "volume",
        "buttons-grid"
      ],
      "widget-config": {
        "title": {
          "text": "Notifications",
          "clear-all-button": true,
          "button-text": "Clear All"
        },
        "dnd": {
          "text": "Do Not Disturb"
        },
        "label": {
          "max-lines": 5,
          "text": "Notification Center"
        },
        "mpris": {
          "image-size": 96,
          "image-radius": 8,
          "loop": true,
          "blacklist": [""]
        },
        "volume": {
          "label": "Volume"
        },

        "buttons-grid": {
          "actions": [
            {
              "label": "",
              "command": "swaylock & niri msg action power-off-monitors"
            },
            {
              "label": "",
              "command": "wlogout -b 4 -T 480 -B 480 -L 300 -R 300"
            }
          ]
        }
      }
    }
  '';

  xdg.configFile."swaync/style.css".text = ''
    * {
      all: unset;
      font-family: Hack, Symbols Nerd Font, monospace;
      font-size: 13px;
    }

    .control-center {
      background: rgba(20, 20, 22, 0.95);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 12px;
      padding: 12px;
    }

    .notification-row {
      outline: none;
      margin: 0;
      padding: 0;
    }

    .notification {
      background: rgba(40, 40, 42, 0.8);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 10px;
      margin: 4px 0;
      padding: 10px;
      transition: background 0.15s ease;
    }

    .notification:hover {
      background: rgba(50, 50, 52, 0.9);
    }

    .notification.default {
      border-color: rgba(255, 255, 255, 0.08);
    }

    .notification.low {
      border-color: rgba(150, 203, 254, 0.3);
    }

    .notification.critical {
      border-color: rgba(255, 108, 96, 0.5);
    }

    .notification-content {
      color: rgba(255, 255, 255, 0.9);
    }

    .summary {
      font-weight: bold;
      color: rgba(255, 255, 255, 0.95);
      font-size: 13px;
    }

    .time {
      color: rgba(255, 255, 255, 0.4);
      font-size: 11px;
    }

    .body {
      color: rgba(255, 255, 255, 0.7);
      font-size: 12px;
      margin-top: 2px;
    }

    .image {
      border-radius: 8px;
    }

    .notification-default-action {
      margin: 0;
      padding: 0;
      border-radius: 10px;
    }

    .close-button {
      background: rgba(255, 255, 255, 0.06);
      border-radius: 6px;
      color: rgba(255, 255, 255, 0.5);
      margin: 2px;
      padding: 2px 6px;
    }

    .close-button:hover {
      background: rgba(255, 108, 96, 0.3);
      color: #ff6c60;
    }

    .notification-actions {
      margin-top: 6px;
    }

    .notification-action {
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 6px;
      color: rgba(255, 255, 255, 0.8);
      padding: 4px 8px;
    }

    .notification-action:hover {
      background: rgba(255, 255, 255, 0.1);
    }

    .control-center-list {
      background: transparent;
    }

    .control-center-list-placeholder {
      color: rgba(255, 255, 255, 0.3);
    }

    .blank-window {
      background: transparent;
    }

    .dnd {
      background: rgba(40, 40, 42, 0.6);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 10px;
      margin: 4px 0;
      padding: 8px 12px;
      color: rgba(255, 255, 255, 0.8);
    }

    .dnd > * {
      margin: 0 4px;
    }

    .dnd slider {
      background: rgba(255, 255, 255, 0.2);
      border-radius: 4px;
    }

    .widget-title {
      color: rgba(255, 255, 255, 0.9);
      font-size: 15px;
      font-weight: bold;
      margin: 4px 0;
      padding: 0 4px;
    }

    .widget-title button {
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 6px;
      color: rgba(255, 255, 255, 0.6);
      padding: 2px 8px;
    }

    .widget-title button:hover {
      background: rgba(255, 255, 255, 0.1);
      color: rgba(255, 255, 255, 0.9);
    }

    .widget-label {
      color: rgba(255, 255, 255, 0.5);
      font-size: 12px;
      margin: 4px 0;
    }

    .widget-mpris {
      background: rgba(40, 40, 42, 0.6);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 10px;
      margin: 4px 0;
      padding: 10px;
    }

    .widget-mpris-player {
      padding: 4px 0;
    }

    .widget-mpris-title {
      font-weight: bold;
      font-size: 13px;
    }

    .widget-mpris-subtitle {
      font-size: 11px;
      color: rgba(255, 255, 255, 0.5);
    }

    .widget-volume {
      background: rgba(40, 40, 42, 0.6);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 10px;
      margin: 4px 0;
      padding: 8px 12px;
      color: rgba(255, 255, 255, 0.8);
    }

    .widget-volume trough {
      background: rgba(255, 255, 255, 0.1);
      border-radius: 4px;
      min-height: 6px;
    }

    .widget-volume highlight {
      background: rgba(150, 203, 254, 0.8);
      border-radius: 4px;
    }

    .widget-backlight {
      background: rgba(40, 40, 42, 0.6);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 10px;
      margin: 4px 0;
      padding: 8px 12px;
      color: rgba(255, 255, 255, 0.8);
    }

    .widget-backlight trough {
      background: rgba(255, 255, 255, 0.1);
      border-radius: 4px;
      min-height: 6px;
    }

    .widget-backlight highlight {
      background: rgba(255, 203, 107, 0.8);
      border-radius: 4px;
    }

    .buttons-grid {
      margin: 4px 0;
    }

    .buttons-grid button {
      background: rgba(40, 40, 42, 0.6);
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 10px;
      padding: 8px 12px;
      min-width: 40px;
    }

    .buttons-grid button:hover {
      background: rgba(50, 50, 52, 0.9);
    }
  '';


  # ── GTK theme (dark mode + Papirus icons) ────────────────────────────────
  # GTK3: use gtk-application-prefer-dark-theme
  # GTK4/libadwaita: use color-scheme in dconf
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };
  dconf.settings."org/gnome/desktop/interface"."color-scheme" = "prefer-dark";

  # ── GNOME keyring (Chrome passwords, SSH/GPG passphrases) ────────────────
  services.gnome-keyring.enable = true;
}
