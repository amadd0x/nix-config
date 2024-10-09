{
  lib,
  pkgs,
  ...
}: {
  networking.hostName = "daedalus";
  networking.firewall.allowedTCPPorts = [
    80
    81
    443
    7654 # Satisfactory-wh
    7777 # Satisfactory
    8080
    8081
    # 25565 # Minecraft
    # 25575 # Minecraft RCON
    7474
    3001
    6379
    3003
    5432
  ];
  networking.firewall.allowedUDPPorts = [
    7654 # Satisfactory-wh
    7777 # Satisfactory
    # 27000 # Avorion game port
    # 27003 # Avorion query port
    # 27021 # Avorion Steam port
  ];

  # Add to /etc/hosts
  networking.hosts = {
    "192.168.0.112" = ["traefik.local" "nomad.traefik.local"];
  };
}
