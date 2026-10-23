{
  config,
  lib,
  pkgs,
  ...
}: let
  # Nightly-ish restic backup of daedalus's service data to atlas
  # (hosts/atlas/services/restic-server.nix), over tailscale.
  #
  # atlas is a desktop and is not always on, so there is no fixed schedule.
  # homelab-backup-trigger runs hourly and starts the backup only when the last
  # success is over 20h old and atlas answers. A few days with atlas off just
  # means the next run catches up.
  #
  # The repository is append-only from here; retention/prune runs on atlas.
  #
  #   sudo restic-atlas snapshots          # list
  #   sudo restic-atlas restore latest --target /tmp/r --include /media/data/docuseal
  #   sudo systemctl start restic-backups-atlas   # back up now
  atlas = "100.83.101.35"; # tailscale IP, so this never depends on pihole
  stateDir = "/var/lib/homelab-backup";
  dumpDir = "${stateDir}/dumps";
  textfileDir = "/var/lib/prometheus-node-exporter-text";
  docker = "${config.virtualisation.docker.package}/bin/docker";

  # Postgres databases, found by the POSTGRES_DB env of the running
  # `database-<alloc>` container. Their data dirs are excluded below: copying a
  # live postgres directory is not a usable backup.
  pgDatabases = ["immich" "paperless" "umami"];

  # Live SQLite databases. Copied with sqlite's online .backup into dumpDir;
  # the raw files are excluded below.
  sqliteDatabases = [
    "/media/data/docuseal/db.sqlite3"
    "/media/data/uptime-kuma/kuma.db"
    "/media/data/picoshare/store.db"
    "/media/data/grafana/grafana.db"
    "/media/data/pihole/etc-pihole/gravity.db"
  ];

  # Save directories only; the server installs around them are re-downloadable.
  # Listed as globs and filtered to what exists, so retiring a game does not
  # break the backup.
  gameSaves = [
    "/media/data/games/ark-asa/server-files/ShooterGame/Saved"
    "/media/data/games/factorio/saves"
    "/media/data/games/minecraft/data"
    "/media/data/games/necesse/saves"
    "/media/data/games/palworld/Pal/Saved"
    "/media/data/games/rimworld-together/data/Assets/Saves"
    "/media/data/games/rimworld-together/data/Assets/World"
    "/media/data/games/satisfactory*/save"
    "/media/data/games/satisfactory*/serverfiles/saved"
    "/media/data/games/satisfactory*/serverfiles/FactoryGame/Saved"
    "/media/data/games/satisfactory*/serverfiles/gamefiles/FactoryGame/Saved"
    "/media/data/games/windrose/server-files/R5/Saved"
  ];

  prepare = pkgs.writeShellScript "homelab-backup-prepare" ''
    set -uo pipefail
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.sqlite pkgs.util-linux]}
    mkdir -p ${dumpDir}/postgres ${dumpDir}/sqlite
    chmod 700 ${stateDir}
    metrics=$(mktemp)

    for db in ${lib.escapeShellArgs pgDatabases}; do
      ok=0
      container=""
      for id in $(${docker} ps --filter name=database- --format '{{.ID}}'); do
        if ${docker} inspect "$id" --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -qx "POSTGRES_DB=$db"; then
          container=$id
          break
        fi
      done
      if [ -z "$container" ]; then
        echo "WARNING: no running postgres container for $db; keeping previous dump" >&2
      else
        user=$(${docker} inspect "$container" --format '{{range .Config.Env}}{{println .}}{{end}}' | sed -n 's/^POSTGRES_USER=//p')
        out=${dumpDir}/postgres/$db.dump
        if ${docker} exec "$container" pg_dump -U "$user" -Fc "$db" > "$out.tmp" \
          && ${docker} exec -i "$container" pg_restore -l < "$out.tmp" > /dev/null; then
          mv "$out.tmp" "$out"
          ok=1
        else
          echo "WARNING: pg_dump of $db failed; keeping previous dump" >&2
          rm -f "$out.tmp"
        fi
      fi
      echo "homelab_backup_dump_success{db=\"$db\"} $ok" >> "$metrics"
    done

    # Run sqlite as the file's owner: opening a WAL database can create -wal
    # and -shm files, and root-owned ones would lock the app out of its own db.
    scratch=$(mktemp -d)
    chmod 777 "$scratch"
    for f in ${lib.escapeShellArgs sqliteDatabases}; do
      [ -f "$f" ] || continue
      ok=0
      name=$(echo "''${f#/media/data/}" | tr / _)
      if setpriv --reuid="$(stat -c %u "$f")" --regid="$(stat -c %g "$f")" --clear-groups \
        sqlite3 "$f" ".backup '$scratch/$name'"; then
        mv "$scratch/$name" ${dumpDir}/sqlite/"$name"
        ok=1
      else
        echo "WARNING: sqlite backup of $f failed; keeping previous copy" >&2
      fi
      echo "homelab_backup_dump_success{db=\"$f\"} $ok" >> "$metrics"
    done
    rm -rf "$scratch"

    chmod 644 "$metrics"
    mv "$metrics" ${textfileDir}/homelab_backup_dumps.prom
  '';

  # ExecStopPost: runs after success and failure alike. SERVICE_RESULT is set
  # by systemd.
  record = pkgs.writeShellScript "homelab-backup-record" ''
    set -u
    now=$(date +%s)
    ok=0
    if [ "$SERVICE_RESULT" = success ]; then
      ok=1
      echo "$now" > ${stateDir}/last-success
    fi
    last=$(cat ${stateDir}/last-success 2>/dev/null || echo 0)
    tmp=$(mktemp ${textfileDir}/.homelab_backup.XXXXXX)
    cat > "$tmp" <<EOF
    # HELP homelab_backup_last_run_timestamp_seconds When the last backup run to atlas finished.
    # TYPE homelab_backup_last_run_timestamp_seconds gauge
    homelab_backup_last_run_timestamp_seconds $now
    # HELP homelab_backup_last_run_success Whether the last backup run to atlas succeeded.
    # TYPE homelab_backup_last_run_success gauge
    homelab_backup_last_run_success $ok
    # HELP homelab_backup_last_success_timestamp_seconds When a backup to atlas last succeeded.
    # TYPE homelab_backup_last_success_timestamp_seconds gauge
    homelab_backup_last_success_timestamp_seconds $last
    EOF
    chmod 644 "$tmp"
    mv "$tmp" ${textfileDir}/homelab_backup.prom
  '';
in {
  sops.secrets.restic-password = {};
  sops.secrets.restic-rest-env = {};

  services.restic.backups.atlas = {
    repository = "rest:http://${atlas}:8000/daedalus/";
    passwordFile = config.sops.secrets.restic-password.path;
    # RESTIC_REST_USERNAME / RESTIC_REST_PASSWORD for atlas's htpasswd.
    environmentFile = config.sops.secrets.restic-rest-env.path;
    initialize = true;

    paths = [
      "/media/data/immich-upload"
      "/media/data/paperless"
      "/media/data/docuseal"
      "/media/data/uptime-kuma"
      "/media/data/pihole"
      "/media/data/traefik"
      "/media/data/picoshare"
      "/media/data/grafana"
      "/media/data/code-server"
      dumpDir
    ];
    dynamicFilesFrom = ''
      for p in ${lib.concatStringsSep " " gameSaves}; do
        [ -e "$p" ] && echo "$p"
      done
      true
    '';
    exclude = [
      # Regenerated by immich.
      "/media/data/immich-upload/thumbs"
      "/media/data/immich-upload/encoded-video"
      # Covered by the dumps in dumpDir.
      "/media/data/paperless/db"
      "/media/data/paperless/redis"
      "/media/data/docuseal/db.sqlite3*"
      "/media/data/uptime-kuma/kuma.db*"
      "/media/data/picoshare/store.db*"
      "/media/data/grafana/grafana.db*"
      # gravity.db is dumped; the rest is the query log and a stale copy.
      "/media/data/pihole/etc-pihole/*.db*"
    ];

    backupPrepareCommand = "${prepare}";
    backupCleanupCommand = "${record}";

    # Started by homelab-backup-trigger instead of a fixed timer.
    timerConfig = null;
    # Append-only repository: forget/prune is not allowed from here.
    pruneOpts = [];
  };

  systemd.services.homelab-backup-trigger = {
    description = "Start the restic backup to atlas when one is due and atlas is up";
    serviceConfig.Type = "oneshot";
    path = [pkgs.coreutils pkgs.curl pkgs.systemd];
    script = ''
      last=$(cat ${stateDir}/last-success 2>/dev/null || echo 0)
      age=$(( $(date +%s) - last ))
      if [ "$age" -lt $(( 20 * 3600 )) ]; then
        exit 0
      fi
      # rest-server answers 401 without credentials; 000 means no connection.
      code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://${atlas}:8000/ || true)
      if [ "$code" = 000 ]; then
        echo "backup due ($(( age / 3600 ))h since last success) but atlas is unreachable; retrying next hour"
        exit 0
      fi
      echo "backup due ($(( age / 3600 ))h since last success); starting restic-backups-atlas"
      systemctl start --no-block restic-backups-atlas.service
    '';
  };

  systemd.timers.homelab-backup-trigger = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "hourly";
      OnBootSec = "15min";
      RandomizedDelaySec = "5min";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0700 root root -"
    "d ${textfileDir} 0755 root root -"
  ];
}
