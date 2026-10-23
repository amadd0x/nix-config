{config, ...}: {
  # Backup target for daedalus (hosts/daedalus/services/backup.nix).
  #
  # Append-only: daedalus can add snapshots but cannot delete or rewrite them,
  # so a compromised daedalus cannot destroy its own backups. Pruning happens
  # here instead, against the repository on local disk.
  #
  # The repository is encrypted with `restic-password`. That password is also
  # kept outside this repo (password manager); without it the backups are
  # unreadable.
  #
  # Ad-hoc access as root:  sudo restic-prune-daedalus snapshots
  services.restic.server = {
    enable = true;
    # Systemd socket. All interfaces, but the firewall only opens it on
    # tailscale0, so the LAN cannot reach it.
    listenAddress = "8000";
    dataDir = "/backups/restic";
    appendOnly = true;
    # Each htpasswd user can only reach /<user>/.
    privateRepos = true;
    htpasswd-file = config.sops.secrets.restic-htpasswd.path;
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [8000];

  sops.secrets.restic-htpasswd.owner = "restic";
  sops.secrets.restic-password.owner = "restic";

  # Retention for daedalus's snapshots, plus a partial integrity check. Runs as
  # the rest-server user so pruned packs keep the same owner. Persistent: atlas
  # is not always on, so a missed week runs at next boot.
  services.restic.backups.prune-daedalus = {
    repository = "/backups/restic/daedalus";
    passwordFile = config.sops.secrets.restic-password.path;
    user = "restic";
    paths = [];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
    runCheck = true;
    checkOpts = ["--read-data-subset=5%"];
    timerConfig = {
      OnCalendar = "Sun 12:00";
      Persistent = true;
    };
  };
}
