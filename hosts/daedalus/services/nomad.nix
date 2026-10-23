{
  lib,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [4646 4647 4648];
  networking.firewall.logRefusedPackets = true; # Enable logging of refused packets, check with journalctl -k
  virtualisation.docker.extraOptions = "--default-ulimit nofile=262144:262144";

  virtualisation.docker.enable = true;
  # pkgs.docker still points at docker_28, which is EOL/insecure-marked
  virtualisation.docker.package = pkgs.docker_29;
  virtualisation.docker.daemon.settings = {
    insecure-registries = ["192.168.0.112:5000"];
  };
  networking.bridges.br0.interfaces = ["eth0"];
  networking.interfaces.br0.useDHCP = true;

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
      cni-plugins
    ];

    settings = {
      name = "daedalus";
      client = {
        cni_path = "${pkgs.cni-plugins}/bin";
        network_interface = "eno50";
        enabled = true;
        options = {
          "driver.raw_exec.enable" = "1";
        };
        host_volume = {
          games = {
            path = "/media/data/games";
            read_only = false;
          };
          immich-upload = {
            path = "/media/data/immich-upload";
            read_only = false;
          };
          immich-cache = {
            path = "/media/data/immich-cache";
            read_only = false;
          };
          photos = {
            path = "/media/data/photos";
            read_only = false;
          };
          immich-db = {
            path = "/media/data/immich-db";
            read_only = false;
          };
          foundry = {
            path = "/media/data/foundry";
            read_only = false;
          };
        };
      };
      server = {
        enabled = true;
        bootstrap_expect = 1;
      };
      plugin = [
        {raw_exec = [{config = [{enabled = true;}];}];}
        {
          docker = [
            {
              config = [
                {
                  volumes = [
                    {
                      enabled = true;
                    }
                  ];
                  allow_privileged = true;
                  allow_caps = [
                    "net_raw"
                    "sys_ptrace"
                    "audit_write"
                    "chown"
                    "dac_override"
                    "fowner"
                    "fsetid"
                    "kill"
                    "mknod"
                    "net_bind_service"
                    "setfcap"
                    "setgid"
                    "setpcap"
                    "setuid"
                    "sys_chroot"
                    "net_admin"
                  ];
                }
              ];
            }
          ];
        }
      ];
      # Scraped by the prometheus nomad job at :4646/v1/metrics?format=prometheus.
      # publish_allocation_metrics is what gives per-task memory and cpu used
      # vs. reserved, the data right-sizing jobs depends on.
      telemetry = {
        prometheus_metrics = true;
        publish_allocation_metrics = true;
        publish_node_metrics = true;
        collection_interval = "10s";
      };
      bind_addr = "0.0.0.0";
      data_dir = "/var/lib/nomad";
      log_rotate_bytes = 1000000;
      advertise = {
        http = "192.168.0.112";
        rpc = "192.168.0.112";
        serf = "192.168.0.112";
      };
    };
  };
}
