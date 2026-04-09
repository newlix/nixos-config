{ config, pkgs, ... }:

{
  # ── btrbk ──────────────────────────────────────────────────────────────────
  # Daily snapshots + send/receive backup to /backup (sdc)
  services.btrbk.instances."backup" = {
    onCalendar = "daily";
    settings = {
      snapshot_preserve_min = "2d";
      snapshot_preserve     = "7d 4w";
      target_preserve_min   = "latest";
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
    # '+' prefix runs as root (btrbk service runs as user btrbk, which cannot mount)
    ExecStartPre = "+-${pkgs.util-linux}/bin/mount /backup";
    # ExecStopPost runs regardless of success/failure; '-' tolerates already-unmounted
    ExecStopPost = "+-${pkgs.util-linux}/bin/umount /backup";
  };
}
