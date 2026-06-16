{ config, pkgs, ... }:

{
  # ── restic → pCloud ────────────────────────────────────────────────────────
  # Secrets (root:root 0600, NOT in git or the nix store):
  #   /etc/secrets/rclone.conf             - rclone OAuth token for pCloud
  #   /etc/secrets/restic-pcloud.password  - restic repository passphrase
  #
  # First-time setup:
  #   1. nix-shell -p rclone
  #      rclone config  →  name: pcloud, type: pcloud, US endpoint (api.pcloud.com)
  #      cp ~/.config/rclone/rclone.conf /etc/secrets/rclone.conf
  #      chmod 600 /etc/secrets/rclone.conf
  #   2. openssl rand -base64 32 > /etc/secrets/restic-pcloud.password
  #      chmod 600 /etc/secrets/restic-pcloud.password
  #   3. restic -r rclone:pcloud:restic-lab \
  #        --rclone-args "--config /etc/secrets/rclone.conf" \
  #        -p /etc/secrets/restic-pcloud.password init
  environment.systemPackages = [ pkgs.rclone ];

  services.restic.backups.pcloud = {
    repository    = "rclone:pcloud:restic-lab";
    rcloneConfigFile = "/etc/secrets/rclone.conf";
    passwordFile  = "/etc/secrets/restic-pcloud.password";
    paths = [
      "/data/@less"
      "/data/@more"
      "/home/newlix/dotfiles"
      "/home/newlix/github"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
    ];
  };

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

  # Telegram alert when btrbk fails (it once failed silently for ~a month, leaving
  # @less/@newlix without offsite backups). Bot token + chat id live in
  # /etc/secrets/telegram.env (root:root 0600, NOT in git or the nix store):
  #     TG_TOKEN=123456:ABC...
  #     TG_CHAT_ID=123456789
  # (Same bot/chat as the dotfiles backup scripts; kept out of the store on purpose.)
  systemd.services."btrbk-notify-failure" = {
    description = "Telegram alert: btrbk backup failed";
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = "-/etc/secrets/telegram.env";
    };
    script = ''
      ${pkgs.curl}/bin/curl -fsS --max-time 20 \
        "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        --data-urlencode "chat_id=$TG_CHAT_ID" \
        --data-urlencode "text=⚠️ btrbk backup FAILED on ${config.networking.hostName} at $(date '+%F %T'). Check: journalctl -u btrbk-backup -e"
    '';
  };

  systemd.services."btrbk-backup".unitConfig.OnFailure = [ "btrbk-notify-failure.service" ];
}
