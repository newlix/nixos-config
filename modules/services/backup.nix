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
      # Shortened from "30d 10w 6m": the old monthly tier pinned large churning
      # @newlix cache snapshots and filled /backup (5.5T). Regenerable caches are
      # now excluded via nested subvolumes (see hardware-configuration.nix / home).
      target_preserve       = "14d 8w 3m";

      volume."/data" = {
        snapshot_dir = "@snapshots";
        # @newlix (the home) is intentionally NOT backed up — only the curated
        # @dotfiles + @github subvolumes mounted into it are. Everything else in
        # home is regenerable (caches, ML models, playground).
        subvolume = {
          "@less".target     = "/backup";
          "@more".target     = "/backup";
          "@dotfiles".target = "/backup";
          "@github".target   = "/backup";
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
