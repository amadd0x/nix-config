# Custom packages, that can be defined similarly to ones from nixpkgs
{pkgs ? import <nixpkgs> {}}: rec {
  code-server = pkgs.callPackage ./code-server.nix {};
}
