{pkgs, ...}: {
  imports = [
    # ./openvpn.nix
    ./nomad.nix
    ./networking.nix
    ./tailscale.nix
    ./syncthing.nix
    ./monitoring.nix
    ./backup.nix
  ];
}
