# Entrypoint for atlas: imports + atlas-only packages.
{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./services
    ../common/global
    ../common/optional/dev.nix
    ../common/optional/workstation.nix
  ];

  # Atlas-only apps. Shared ones live in ../common/optional/{workstation,dev}.nix.
  environment.systemPackages = with pkgs; [
    copyq
    libva-utils
    fswebcam
    cowsay
    firefox
    asciinema
    asciinema-agg
    audacity
    variety
    termius
    rustdesk
    pkgs.unstable.antigravity-ide
    # Horizon launcher (FHS env, self-update off: updates come from flake.lock).
    inputs.horizon.packages.${pkgs.stdenv.hostPlatform.system}.horizon-launcher
  ];
}
