# Entrypoint for hermes: imports + hermes-only packages.
{pkgs, ...}: {
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ../common/global
    ../common/optional/dev.nix
    ../common/optional/workstation.nix
    ../common/optional/tailscale.nix
  ];

  # Hermes-only apps. Shared ones live in ../common/optional/{workstation,dev}.nix.
  environment.systemPackages = with pkgs; [
    pkgs.unstable.code-cursor
  ];
}
