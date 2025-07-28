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
    2283 # Immich
    # 7654 # Satisfactory-wh
    # 7777 # Satisfactory
    7474
    8080
    8081
    8082
    8085
    8384 # Syncthing
    25555 # Rimworld
    # 25565 # Minecraft
    # 25575 # Minecraft RCON
    26706 # reactive-resume
  ];
  networking.firewall.allowedUDPPorts = [
    # 7654 # Satisfactory-wh
    # 7777 # Satisfactory
    # 27000 # Avorion game port
    # 27003 # Avorion query port
    # 27021 # Avorion Steam port
  ];

  # Add to /etc/hosts
  networking.hosts = {
    "192.168.0.112" = ["traefik.local" "nomad.traefik.local" "immich.traefik.local"];
  };
}
