{
  lib,
  pkgs,
  ...
}: {
  networking.hostName = "daedalus";
  networking.firewall.allowedTCPPorts = [
    53
    80
    81
    443
    2283 # Immich
    5000 # Registry
    # 7654 # Satisfactory-wh
    # 7777 # Satisfactory
    7474
    7756
    8080
    8081
    8082
    8085
    8384 # Syncthing
    18789
    # 25555 # Rimworld
    # 25565 # Minecraft
    # 25575 # Minecraft RCON
    26706 # reactive-resume
  ];
  networking.firewall.allowedUDPPorts = [
    53
    # 7654 # Satisfactory-wh
    # 7777 # Satisfactory
    # 27000 # Avorion game port
    # 27003 # Avorion query port
    # 27021 # Avorion Steam port
    # 14159 # necesse
  ];

  # daedalus resolves via MagicDNS (100.100.100.100), which forwards to pihole
  # running on daedalus itself. When pihole is down (e.g. after a power outage)
  # docker can't pull pihole's own image. Append public resolvers so lookups
  # fall through on SERVFAIL/unreachable; openresolv appends these even though
  # tailscale registers its nameserver as exclusive. glibc uses at most 3.
  networking.resolvconf.extraConfig = ''
    name_servers_append="1.1.1.1 9.9.9.9"
  '';
  networking.resolvconf.extraOptions = ["timeout:2"];

  # Add to /etc/hosts
  networking.hosts = {
    "192.168.0.112" = [
      "traefik.local"
      "nomad.traefik.local"
      "immich.traefik.local"
      "paperless.traefik.local"
      "openhands.traefik.local"
    ];
  };
}
