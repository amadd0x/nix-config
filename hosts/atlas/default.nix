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
    ../common/optional/dev.nix
    ../common/optional/known-hosts.nix
  ];

  environment.systemPackages = with pkgs; [
    # Atlas-specific apps. Shared dev tooling lives in ../common/optional/dev.nix.
    remmina
    mailutils
    busybox
    unrar-wrapper
    xclip
    copyq
    glib-networking
    libva-utils
    flameshot
    fswebcam
    ghostty
    termdown
    peek
    inkscape
    qFlipper
    vlc
    memtester
    zsh
    zsh-powerlevel10k
    zsh-autosuggestions
    zsh-syntax-highlighting
    cowsay

    google-chrome
    firefox
    slack
    prismlauncher
    teams-for-linux
    asciinema
    asciinema-agg
    audacity
    variety

    pkgs.unstable.antigravity
    termius
    lmstudio
    rustdesk

    discord
    steam
    pkgs.unstable.code-server
  ];

  environment.variables = {EDITOR = "code --wait";};

  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
}
