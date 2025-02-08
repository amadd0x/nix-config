{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  services.openvpn.servers = {
    figgVPN = {
      config = ''config /etc/openvpn/client/client.conf'';
      updateResolvConf = true;
      autoStart = false;
      # authUserPass.username = ''$(cat /run/secrets/ovpn-user)'';
      # authUserPass.password = ''$(cat /run/secrets/ovpn-pass)'';
    };
  };
}
