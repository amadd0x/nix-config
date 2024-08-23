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
    8080
    8081
    25565 # Minecraft
    25575 # Minecraft RCON
  ];

  # Add to /etc/hosts
  networking.hosts = {
    "192.168.0.112" = ["traefik.local" "nomad.traefik.local"];
  };
}
