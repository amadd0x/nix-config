{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.hardware.flipperzero;
in {
  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.qFlipper];
    services.udev.packages = [pkgs.qFlipper];
  };
}
