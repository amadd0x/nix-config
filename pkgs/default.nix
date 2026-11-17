# Custom packages, that can be defined similarly to ones from nixpkgs.
# Exposed as `pkgs.<name>` via the `additions` overlay. Example:
#   my-tool = pkgs.callPackage ./my-tool.nix {};
{pkgs ? import <nixpkgs> {}}: {
}
