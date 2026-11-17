# Nix itself: flakes, store optimisation, and pinning the flake's inputs
# into the registry and NIX_PATH so `nix run nixpkgs#...` and <nixpkgs>
# use the same nixpkgs as the system.
{
  inputs,
  lib,
  config,
  ...
}: {
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      # Deduplicate the store by hardlinking identical files.
      auto-optimise-store = true;
    };

    # Each flake input as a registry entry (nix3 commands).
    registry = lib.mapAttrs (_: flake: {inherit flake;}) (lib.filterAttrs (_: lib.isType "flake") inputs);

    # ...and as a legacy channel (<nixpkgs>, nix-shell -p).
    nixPath = ["/etc/nix/path"];
  };

  environment.etc =
    lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  # Add ~/.local/bin to $PATH.
  environment.localBinInPath = true;
}
