{
  lib,
  pkgs,
  ...
}: {
  services.rustdesk-server = {
    enable = true;
    openFirewall = true;
    signal.relayHosts = ["192.168.0.118"];
  };

  # Websocket ports (21118/21119) aren't covered by openFirewall; open for web client use.
  networking.firewall.allowedTCPPorts = [21118 21119];
}
