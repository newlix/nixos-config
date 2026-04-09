{ config, pkgs, ... }:

{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        # Command → Ctrl（App 快捷鍵）
        leftmeta = "leftcontrol";
        rightmeta = "rightcontrol";
        # Option → Super（Niri Mod 鍵）
        leftalt = "leftmeta";
        rightalt = "rightmeta";
        # Caps Lock → Ctrl+Space（輸入法切換）
        capslock = "C-space";
      };
    };
  };

  # F1–F12 預設為標準 F 鍵，fn+F 才是多媒體鍵
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';
}
