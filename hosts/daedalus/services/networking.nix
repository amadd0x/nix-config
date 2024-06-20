{
  lib,
  pkgs,
  ...
}: {
  networking.hostName = "daedalus";
  networking.firewall.allowedTCPPorts = [8080 8081];

  # Add to /etc/hosts
  networking.extraHosts = ''
    192.168.0.112 traefik.local
    192.168.0.112 nomad.traefik.local
  '';
}
