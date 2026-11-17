{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  system.autoUpgrade = {
    # Opt-in per host: set `system.autoUpgrade.enable = true;` in a host config.
    enable = lib.mkDefault false;
    dates = lib.mkDefault "09:00";
    randomizedDelaySec = lib.mkDefault "45min";
    flags = [
      "--refresh"
      "-L"
    ];
    # Must NOT be inputs.self.outPath -- see the note in hosts/atlas/configuration.nix.
    flake = lib.mkDefault "github:amadd0x/nix-config";
  };

  # Only run if current config (self) is older than the new one.
  systemd.services.nixos-upgrade = lib.mkIf config.system.autoUpgrade.enable {
    serviceConfig.ExecCondition = lib.getExe (
      pkgs.writeShellScriptBin "check-date" ''
        lastModified() {
          nix flake metadata "$1" --refresh --json | ${lib.getExe pkgs.jq} '.lastModified'
        }
        test "$(lastModified "${config.system.autoUpgrade.flake}")"  -gt "$(lastModified "self")"
      ''
    );
  };
}
