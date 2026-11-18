# Entrypoint for hermes: imports + hermes-only packages.
{
  pkgs,
  inputs,
  ...
}: let
  horizonLauncher = inputs.horizon.packages.${pkgs.stdenv.hostPlatform.system}.horizon-launcher;

  # The flake builds the launcher from source without Horizon's Microsoft sign-in
  # client ID (release builds get it at compile time from a CI variable), so set it
  # at run time. Value read from the official launcher@0.2.70 release binary.
  horizonLauncherWithMsa = pkgs.symlinkJoin {
    name = "horizon-launcher-with-msa";
    paths = [horizonLauncher];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/horizon-launcher \
        --set-default HORIZON_MSA_CLIENT_ID 331e08f8-172d-43b9-835a-3108c2fcdbf3
    '';
  };
in {
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
    horizonLauncherWithMsa
  ];
}
