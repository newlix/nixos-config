{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ../../home/common.nix ];

  home.username = "newlix";
  home.homeDirectory = "/home/newlix";
  home.stateVersion = "25.05";

  # Lab-specific packages (NVIDIA GPU available)
  home.packages = with pkgs; [
    ffmpeg
  ];

  programs.bash.shellAliases = {
    open = "nautilus";
  };

  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      thumbfast
      autoload
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
    spawn-at-startup "walker" "--gapplication-service"

    prefer-no-csd
    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

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
        Mod+B { spawn "google-chrome-stable" "--new-window" "about:blank"; }
        Mod+G { spawn "google-chrome-stable" "--app=https://gemini.google.com"; }
        Super+Space { spawn "walker"; }
        Ctrl+Mod+Q { spawn "swaylock"; }

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
        Mod+H     { focus-column-left; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }
        Mod+L     { focus-column-right; }

        Mod+Ctrl+Left  { move-column-left; }
        Mod+Ctrl+Down  { move-window-down; }
        Mod+Ctrl+Up    { move-window-up; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+H     { move-column-left; }
        Mod+Ctrl+J     { move-window-down; }
        Mod+Ctrl+K     { move-window-up; }
        Mod+Ctrl+L     { move-column-right; }

        Mod+Home { focus-column-first; }
        Mod+End  { focus-column-last; }
        Mod+Ctrl+Home { move-column-to-first; }
        Mod+Ctrl+End  { move-column-to-last; }

        Mod+Shift+Left  { focus-monitor-left; }
        Mod+Shift+Down  { focus-monitor-down; }
        Mod+Shift+Up    { focus-monitor-up; }
        Mod+Shift+Right { focus-monitor-right; }
        Mod+Shift+H     { focus-monitor-left; }
        Mod+Shift+J     { focus-monitor-down; }
        Mod+Shift+K     { focus-monitor-up; }
        Mod+Shift+L     { focus-monitor-right; }

        Mod+Page_Down { focus-workspace-down; }
        Mod+Page_Up   { focus-workspace-up; }
        Mod+U         { focus-workspace-down; }
        Mod+I         { focus-workspace-up; }
        Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
        Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
        Mod+Ctrl+U         { move-column-to-workspace-down; }
        Mod+Ctrl+I         { move-column-to-workspace-up; }

        Mod+Shift+Page_Down { move-workspace-down; }
        Mod+Shift+Page_Up   { move-workspace-up; }
        Mod+Shift+U         { move-workspace-down; }
        Mod+Shift+I         { move-workspace-up; }

        Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
        Mod+WheelScrollUp   cooldown-ms=150 { focus-workspace-up; }
        Mod+WheelScrollRight { focus-column-right; }
        Mod+WheelScrollLeft  { focus-column-left; }

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

        Mod+BracketLeft  { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }
        Mod+Comma  { consume-window-into-column; }
        Mod+Period { expel-window-from-column; }

        Mod+R { switch-preset-column-width; }
        Mod+Shift+R { switch-preset-window-height; }
        Mod+Ctrl+R { reset-window-height; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+Ctrl+F { expand-column-to-available-width; }
        Mod+C { center-column; }
        Mod+Ctrl+C { center-visible-columns; }

        // Mod+Minus { set-column-width "-10%"; }
        // Mod+Equal { set-column-width "+10%"; }
        // Mod+Shift+Minus { set-window-height "-10%"; }
        // Mod+Shift+Equal { set-window-height "+10%"; }

        Mod+V       { toggle-window-floating; }
        Mod+Shift+V { switch-focus-between-floating-and-tiling; }

        Ctrl+Shift+3 { screenshot-screen; }
        Ctrl+Shift+4 { screenshot; }
        Ctrl+Shift+5 { screenshot-window; }

        Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
        Ctrl+Shift+Q { quit; }
        Mod+Shift+P { power-off-monitors; }
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
        "custom/files"
        "custom/chrome"
        "custom/gemini"
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
      ];

      "niri/window" = {
        format = "{}";
        max-length = 50;
        separate-outputs = true;
      };

      "niri/workspaces" = {
        format = "{icon}";
        format-icons = {
          "1" = "play";
          "2" = "main";
        };
      };

      "custom/gemini" = {
        format = "Gemini";
        tooltip = false;
        on-click = "google-chrome-stable --app=https://gemini.google.com";
      };

      "custom/chrome" = {
        format = "Chrome";
        tooltip = false;
        on-click = "google-chrome-stable --new-window about:blank";
      };

      "custom/files" = {
        format = "Files";
        tooltip = false;
        on-click = "nautilus --new-window";
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
        on-click = "swaylock";
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
      #custom-files,
      #custom-chrome,
      #custom-gemini,
      #custom-sysinfo,
      #custom-netspeed,
      #clock,
      #wireplumber {
        padding: 4px 12px;
        color: rgba(255, 255, 255, 0.85);
        transition: background-color 0.15s ease;
      }

      /* Hover */
      #custom-lock:hover,
      #custom-files:hover,
      #custom-chrome:hover,
      #custom-gemini:hover,
      #custom-sysinfo:hover,
      #custom-netspeed:hover,
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
  xdg.dataFile."thumbnailers/ffmpegthumbnailer.thumbnailer".text = ''
    [Thumbnailer Entry]
    TryExec=ffmpegthumbnailer
    Exec=ffmpegthumbnailer -i %i -o %o -s %s -q 10
    MimeType=video/jpeg;video/mp4;video/mpeg;video/quicktime;video/x-ms-asf;video/x-ms-wmv;video/x-msvideo;video/x-flv;video/pascal;video/x-matroska;video/x-m4v;video/x-ogm+ogg;video/unknown;video/x-flic;video/x-theora+ogg;video/x-matroska-3d;
  '';

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

      # Audio → Amberol
      "audio/mpeg" = [ "io.bassi.Amberol.desktop" ];
      "audio/flac" = [ "io.bassi.Amberol.desktop" ];
      "audio/x-flac" = [ "io.bassi.Amberol.desktop" ];
      "audio/ogg" = [ "io.bassi.Amberol.desktop" ];
      "audio/x-vorbis+ogg" = [ "io.bassi.Amberol.desktop" ];
      "audio/opus" = [ "io.bassi.Amberol.desktop" ];
      "audio/aac" = [ "io.bassi.Amberol.desktop" ];
      "audio/mp4" = [ "io.bassi.Amberol.desktop" ];
      "audio/x-m4a" = [ "io.bassi.Amberol.desktop" ];
      "audio/wav" = [ "io.bassi.Amberol.desktop" ];
      "audio/x-wav" = [ "io.bassi.Amberol.desktop" ];
      "audio/x-ms-wma" = [ "io.bassi.Amberol.desktop" ];
    };
  };

  # ── Desktop Entries ─────────────────────────────────────────────────────
  xdg.desktopEntries.steam = {
    name = "Steam";
    comment = "Application for managing and playing games on Steam";
    exec = "steam-run %U";
    icon = "steam";
    categories = [ "Game" "Network" "FileTransfer" ];
    terminal = false;
    mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
    settings = {
      # Steam's bwrap uses --chdir "$(pwd)"; walker's cwd may not exist
      # inside the sandbox, so pin it to $HOME.
      Path = "/home/newlix";
      PrefersNonDefaultGPU = "true";
      X-KDE-RunOnDiscreteGpu = "true";
      StartupWMClass = "steam";
    };
  };

  xdg.desktopEntries.zed = {
    name = "Zed";
    exec = "zeditor %F";
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

  # ── USB automount ────────────────────────────────────────────────────────
  services.udiskie.enable = true;

  # ── Notifications ────────────────────────────────────────────────────────
  services.mako.enable = true;

  # ── GNOME keyring (Chrome passwords, SSH/GPG passphrases) ────────────────
  services.gnome-keyring.enable = true;
}
