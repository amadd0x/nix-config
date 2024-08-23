{
  lib,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [4646 4647 4648];
  networking.firewall.logRefusedPackets = true; # Enable logging of refused packets, check with journalctl -k

  services.nomad = {
    enable = true;
    package = pkgs.nomad_1_6;
    enableDocker = true;
    dropPrivileges = false;
    extraPackages = with pkgs; [
      busybox
      curl
      jq
      awscli2
      nomad_1_6
      docker
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
        {nvidia = [{config = [{enabled = true;}];}];}
      ];
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
}
