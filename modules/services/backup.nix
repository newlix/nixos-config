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
      # Keep it simple: 7 daily + 4 weekly (~1 month), no monthly tier — matches
      # the local snapshot_preserve. The old "30d 10w 6m" monthly tier pinned
      # large churning snapshots and filled /backup (5.5T).
      target_preserve       = "7d 4w";

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
