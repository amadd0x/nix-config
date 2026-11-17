{
  lib,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [4646 4647 4648];
  networking.firewall.logRefusedPackets = true; # Enable logging of refused packets, check with journalctl -k

  services.nomad = {
    enable = true;
    package = pkgs.nomad_1_9;
    enableDocker = true;
    dropPrivileges = false;
    extraPackages = with pkgs; [
      busybox
      curl
      jq
      awscli2
      nomad_1_9
      docker_29
    ];

    settings = {
      name = "atlas";
      client = {
        enabled = true;
        servers = ["192.168.0.112"];
        options = {
          "driver.raw_exec.enable" = "1";
        };
        host_volume = {
          nomad = {
            path = "/etc/nomad";
            read_only = false;
          };
        };
        drain_on_shutdown = {
          deadline = "5m";
          ignore_system_jobs = false;
          force = false;
        };
      };
      plugin = [
        {raw_exec = [{config = [{enabled = true;}];}];}
        {docker = [{config = [{volumes = [{enabled = true;}];}];}];}
        {nomad-device-nvidia = [{config = [{enabled = true;} {fingerprint_period = "1m";}];}];}
      ];
      # LAB-9: must match the server (daedalus); see nomad-jobs/acl/README.md.
      acl = {
        enabled = true;
      };
      bind_addr = "0.0.0.0";
      data_dir = "/var/lib/nomad";
      log_rotate_bytes = 1000000;
      advertise = {
        http = "192.168.0.118";
        rpc = "192.168.0.118";
        serf = "192.168.0.118";
      };
    };
  };

  # Nomad fingerprints the default interface and advertises 192.168.0.118, which
  # DHCP assigns during boot. The upstream unit already waits for
  # network-online.target (which needs NetworkManager-wait-online enabled); the
  # slower restart is a fallback so a few early failures don't hit the start limit.
  systemd.services.nomad.serviceConfig.RestartSec = lib.mkForce "5s";
}
