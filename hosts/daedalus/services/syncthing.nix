{
  lib,
  pkgs,
  ...
}: {
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    guiAddress = "192.168.0.112:8384";
  };
}
