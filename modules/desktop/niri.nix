{ config, pkgs, ... }:

{
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
}
