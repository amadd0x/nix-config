{
  lib,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [4646 4647];
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
      name = "daedalus";
      client = {
        enabled = true;
        options = {
          "driver.raw_exec.enable" = "1";
        };
        host_volume = {
          games = {
            path = "/media/data/games";
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
        {docker = [{config = [{volumes = [{enabled = true;}];}];}];}
      ];
      bind_addr = "192.168.0.112";
      data_dir = "/var/lib/nomad";
      # log_rotate_bytes = 1000000;
      advertise = {
        http = "192.168.0.112";
        rpc = "192.168.0.112";
        serf = "192.168.0.112";
      };
    };
  };
}
