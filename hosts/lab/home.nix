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
      "Alt+LEFT" = "playlist-prev";
      "Alt+RIGHT" = "playlist-next";
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
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
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
    spawn-at-startup "waybar"
    spawn-at-startup "walker" "--gapplication-service"
    spawn-sh-at-startup "sleep 2 && mako"

    prefer-no-csd
    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    window-rule {
        match app-id=r#"^org\.wezfurlong\.wezterm$"#
        default-column-width {}
    }
    window-rule {
        match app-id=r#"firefox$"# title="^Picture-in-Picture$"
        open-floating true
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
        Super+Alt+L { spawn "swaylock"; }

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
        Mod+Shift+Q { close-window; }

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

        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }

        Mod+V       { toggle-window-floating; }
        Mod+Shift+V { switch-focus-between-floating-and-tiling; }

        Mod+Shift+3 { screenshot-screen; }
        Mod+Shift+4 { screenshot; }
        Mod+Shift+5 { screenshot-window; }

        Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
        Mod+Shift+E { quit; }
        Ctrl+Alt+Delete { quit; }
        Mod+Shift+P { power-off-monitors; }
    }
  '';

  # ── waybar ─────────────────────────────────────────────────────────────────
  programs.waybar = {
    enable = true;
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
        exec = "while true; do cpu=$(awk '{u=$2+$4; t=$2+$4+$5; if(NR>1) printf \"%.0f\", (u-ou)/(t-ot)*100; ou=u; ot=t}' <(grep '^cpu ' /proc/stat) <(sleep 1; grep '^cpu ' /proc/stat)); mem=$(free | awk '/Mem/{printf \"%.0f\", $3/$2*100}'); temp=$(cat /sys/class/hwmon/hwmon4/temp1_input 2>/dev/null); temp=$((temp/1000)); echo \"CPU \${cpu}%  RAM \${mem}%  \${temp}°C\"; sleep 4; done";
        return-type = "";
        tooltip = false;
        on-click = "foot -e btop";
      };

      "custom/netspeed" = {
        exec = "rx0=0; tx0=0; while true; do read rx1 < /sys/class/net/eno1/statistics/rx_bytes 2>/dev/null || rx1=0; read tx1 < /sys/class/net/eno1/statistics/tx_bytes 2>/dev/null || tx1=0; if [ $rx0 -gt 0 ]; then rxs=$(( (rx1-rx0)/5 )); txs=$(( (tx1-tx0)/5 )); if [ $rxs -gt 1048576 ]; then rxf=$(printf '%5.1fM' $(echo \"scale=1; $rxs/1048576\" | bc)); elif [ $rxs -gt 1024 ]; then rxf=$(printf '%5dK' $(($rxs/1024))); else rxf=$(printf '%5dB' $rxs); fi; if [ $txs -gt 1048576 ]; then txf=$(printf '%5.1fM' $(echo \"scale=1; $txs/1048576\" | bc)); elif [ $txs -gt 1024 ]; then txf=$(printf '%5dK' $(($txs/1024))); else txf=$(printf '%5dB' $txs); fi; else rxf=$(printf '%5dB' 0); txf=$(printf '%5dB' 0); fi; rx0=$rx1; tx0=$tx1; echo \"▼\${rxf} ▲\${txf}\"; sleep 5; done";
        return-type = "";
        tooltip = false;
      };

      "clock" = {
        format = "{:%a %b %d %I:%M %p}";
        tooltip-format = "<big>{:%Y %B}</big>\\n<tt><small>{calendar}</small></tt>";
        interval = 1;
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
        "selection-target" = "clipboard";
      };
      mouse = {
        hide-when-typing = "yes";
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

  # ── Fcitx5 ────────────────────────────────────────────────────────────────
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
}
