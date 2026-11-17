# System packages, ./pkgs, and shell configuration
{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./shell/zsh.nix
    ../common/global
    ../common/optional/dev.nix
    ../common/optional/tailscale.nix
  ];

  # Hermes-specific apps. Shared dev tooling lives in ../common/optional/dev.nix.
  environment.systemPackages = with pkgs; [
    remmina
    mailutils
    busybox
    unrar-wrapper
    xclip
    glib-networking
    flameshot
    termdown
    peek
    inkscape
    qFlipper
    vlc
    memtester
    ghostty
    zsh
    zsh-powerlevel10k
    zsh-autosuggestions
    zsh-syntax-highlighting

    google-chrome
    slack
    prismlauncher
    teams-for-linux
    pkgs.unstable.code-cursor
    lmstudio

    discord
    steam
    pkgs.unstable.code-server
  ];

  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
}
