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
    # The module already passes --refresh.
    flags = ["-L"];
    # Must NOT be inputs.self.outPath. That is a /nix/store path, and pairing it
    # with a lock-file update makes nixos-rebuild write flake.lock back into the
    # store. With auto-optimise-store hardlinking identical files, one such write
    # corrupts every store path sharing that file, which then fails the NAR hash
    # check on any nix copy / nix-copy-closure.
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
