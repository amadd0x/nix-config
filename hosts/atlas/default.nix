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
    openvpn3
    openssl
    remmina
    coreutils
    mailutils
    shellcheck
    busybox
    unrar-wrapper
    update-resolv-conf
    xclip
    glib-networking
    libva-utils
    gnumake
    flameshot
    fswebcam
    ghostty
    termdown
    rclone
    peek
    inkscape
    qFlipper
    zip
    vlc
    # barrier
    memtester
    age
    sops
    zsh
    zsh-powerlevel10k
    zsh-autosuggestions
    zsh-syntax-highlighting

    nil # Nix LSP
    nixd
    nixfmt # Nix formatter
    alejandra

    google-chrome
    firefox
    slack
    # citrix_workspace_24_02_0
    prismlauncher
    teams-for-linux
    jira-cli-go
    asciinema
    asciinema-agg
    audacity
    variety

    pkgs.unstable.code-cursor
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
    devpod
    packer
    postgresql
    promql-cli
    ngrok
    lmstudio
    docker-compose
    (azure-cli.withExtensions [
      pkgs.azure-cli-extensions.trustedsigning 
      pkgs.azure-cli-extensions.automation
      ]
    )

    pkgs.unstable.scalr-cli
    python313
    poetry
    nodejs

    ssm-session-manager-plugin

    discord
    steam
    pkgs.unstable.code-server
  ];

  environment.variables = {EDITOR = "code --wait";};

  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
}
