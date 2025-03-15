{
  lib,
  pkgs,
  ...
}: {
  networking.hostName = "atlas";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [
    2455
  ];

  # Add to /etc/hosts
  networking.hosts = {
    "192.168.0.112" = ["traefik.local" "nomad.traefik.local" "immich.traefik.local"];
  };
}
