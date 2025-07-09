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
  ];

  environment.systemPackages = with pkgs; [
    fd
    jq
    gh
    git
    openvpn
    coreutils
    mailutils
    shellcheck
    busybox
    unrar-wrapper
    update-resolv-conf
    xclip
    glib-networking
    gnumake
    flameshot
    termdown
    peek
    inkscape
    qFlipper
    zip
    vlc
    barrier
    memtester
    age
    sops
    zsh
    zsh-powerlevel10k
    zsh-autosuggestions
    zsh-syntax-highlighting

    nil # Nix LSP
    nixfmt # Nix formatter
    alejandra

    google-chrome
    firefox
    slack
    citrix_workspace_24_02_0
    prismlauncher

    vscode
    vscode-extensions.github.copilot
    vscode-extensions.hashicorp.terraform
    vscode-extensions.bbenoist.nix

    go
    goreleaser
    tfswitch
    tfsec
    pkgs.unstable.awscli2
    nomad
    damon
    packer
    promql-cli
    ngrok
    lmstudio
    docker-compose
    azure-cli
    python313Packages.pip

    ssm-session-manager-plugin

    discord
    steam

    # From ./pkgs
    code-server
  ];

  environment.variables = {
    EDITOR = "code --wait";
  };
}
