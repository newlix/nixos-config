{ config, pkgs, lib, ... }:

{
  # ── PTT Crawler PostgreSQL backup ──────────────────────────────────────────
  # pg_dump (custom format, compressed) every 12 hours with 7-day local rotation.
  # Dumps live in /home/newlix/ptt/backups/ and are included in restic → pCloud
  # offsite backup (paths merge automatically with backup.nix).
  #
  # Restore: docker cp <file>.dump ptt-db-1:/tmp/ && \
  #          docker exec ptt-db-1 pg_restore -U ptt -d ptt --clean /tmp/<file>.dump

  services.restic.backups.pcloud.paths = [
    "/home/newlix/ptt/backups"
  ];

  systemd.services.ptt-backup = {
    description = "PTT Crawler PostgreSQL backup";
    serviceConfig = {
      Type = "oneshot";
      User = "newlix";
    };
    path = [ pkgs.docker ];
    script = ''
      set -euo pipefail
      BACKUP_DIR=/home/newlix/ptt/backups
      TIMESTAMP=$(${pkgs.coreutils}/bin/date +%Y%m%d_%H%M%S)
      FILENAME="ptt_$TIMESTAMP.dump"
      FILEPATH="$BACKUP_DIR/$FILENAME"

      mkdir -p "$BACKUP_DIR"

      echo "[$(date)] backing up ptt database..."
      docker exec ptt-db-1 pg_dump -U ptt -Fc ptt > "$FILEPATH"

      SIZE=$(${pkgs.coreutils}/bin/du -h "$FILEPATH" | cut -f1)
      echo "[$(date)] backup complete: $FILENAME ($SIZE)"

      # Rotate: delete backups older than 7 days
      ${pkgs.findutils}/bin/find "$BACKUP_DIR" -name "ptt_*.dump" -mtime +7 -delete
      echo "[$(date)] rotated backups older than 7 days"
    '';
  };

  systemd.timers.ptt-backup = {
    description = "PTT Crawler PostgreSQL backup (every 12h)";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "04:00,16:00";
      Persistent = true;
    };
  };

  # ── Crawler health monitoring ──────────────────────────────────────────────
  # Checks Docker container health every 10 min. Sends Telegram alert if the
  # crawler is unhealthy or not running. Reuses the same bot/chat as btrbk.
  systemd.services.ptt-monitor = {
    description = "PTT Crawler health check";
    serviceConfig = {
      Type = "oneshot";
      User = "newlix";
      EnvironmentFile = "-/etc/secrets/telegram.env";
    };
    path = [ pkgs.docker pkgs.curl ];
    script = ''
      STATUS=$(docker inspect --format='{{.State.Health.Status}}' ptt-crawler-1 2>/dev/null || echo "missing")
      if [ "$STATUS" != "healthy" ]; then
        ${pkgs.curl}/bin/curl -fsS --max-time 20 \
          "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
          --data-urlencode "chat_id=$TG_CHAT_ID" \
          --data-urlencode "text=⚠️ PTT crawler is $STATUS on ${config.networking.hostName} at $(date '+%F %T'). Check: docker logs ptt-crawler-1"
        echo "alert sent: crawler is $STATUS"
      fi
    '';
  };

  systemd.timers.ptt-monitor = {
    description = "PTT Crawler health check (every 10 min)";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "10min";
    };
  };
}
