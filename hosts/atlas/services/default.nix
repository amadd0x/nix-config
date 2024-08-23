{pkgs, ...}: {
  imports = [
    # ./openvpn.nix
    ./flipperq.nix
    ./nvidia.nix
    ./tailscale.nix
    ./openvpn.nix
    ./networking.nix
    ./nomad.nix
  ];
}
