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
    ./services
    ../common/global
  ];

  environment.systemPackages = with pkgs; [
    fd
    jq
    git
    coreutils
    busybox
    xclip
    glib-networking
    gnumake
    zip
    nano
    wget
    curl

    zsh
    zsh-powerlevel10k
    zsh-autosuggestions
    zsh-syntax-highlighting

    nomad
    packer
    tailscale
    cloudflared

    code-server
    scanmem
  ];
}
