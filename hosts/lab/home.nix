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
