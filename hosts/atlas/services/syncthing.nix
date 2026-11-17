{
  lib,
  pkgs,
  ...
}: {
  services.syncthing = {
    enable = true;
    user = "amaddox";
    openDefaultPorts = true;
    guiAddress = "192.168.0.118:8384";
  };

  # The GUI binds to the LAN address, which DHCP assigns during boot. Without
  # this, syncthing can start first, fail to bind, and hit systemd's restart
  # limit (seen on atlas's first 26.05 boot).
  systemd.services.syncthing = {
    wants = ["network-online.target"];
    after = ["network-online.target"];
    serviceConfig.RestartSec = "5s";
  };
}
