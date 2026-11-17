# Development tooling shared by the workstations (atlas, hermes).
# Host-specific apps stay in each host's default.nix.
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # CLI basics
    fd
    jq
    gh
    git
    openssl
    coreutils
    shellcheck
    gnumake
    zip
    rclone
    age
    sops
    jira-cli-go
    taskwarrior3

    # VPN
    openvpn
    openvpn3
    update-resolv-conf

    # Nix
    nil # Nix LSP
    nixd
    nixfmt # Nix formatter
    alejandra

    # Editors / AI
    vscode
    vscode-extensions.github.copilot
    vscode-extensions.hashicorp.terraform
    vscode-extensions.bbenoist.nix
    pkgs.unstable.claude-code

    # Languages
    go
    goreleaser
    python313
    poetry
    nodejs

    # Infra / cloud
    tfswitch
    tfsec
    pkgs.unstable.awscli2
    ssm-session-manager-plugin
    (
      azure-cli.withExtensions [
        pkgs.azure-cli-extensions.trustedsigning
        pkgs.azure-cli-extensions.automation
        pkgs.azure-cli-extensions.resource-graph
        pkgs.azure-cli-extensions.ad
        pkgs.azure-cli-extensions.webapp
        pkgs.azure-cli-extensions.azure-devops
      ]
    )
    pkgs.unstable.scalr-cli
    nomad
    damon
    devpod
    packer
    postgresql
    promql-cli
    ngrok
    stripe-cli
    docker-compose
  ];

  # Docker
  virtualisation.docker.enable = true;
  # pkgs.docker still points at docker_28, which is EOL/insecure-marked
  virtualisation.docker.package = pkgs.docker_29;

  # Run unpatched dynamic binaries (language toolchains, downloaded CLIs, etc.)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
  ];

  # direnv + nix-direnv, hooked into zsh: loads a project's `use flake` dev shell on cd
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
