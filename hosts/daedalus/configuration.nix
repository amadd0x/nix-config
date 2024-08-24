{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    # Configure your nixpkgs instance
    config = {
      allowUnfree = true;
    };
  };
  nix.registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);
  nix.nixPath = ["/etc/nix/path"];
  environment.etc =
    lib.mapAttrs'
    (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  # Add ~/.local/bin/ to $PATH
  environment.localBinInPath = true;

  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Chicago";

  # User accounts
  users.users = {
    amaddox = {
      isNormalUser = true;
      description = "Austin Maddox";
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEKt24WTdgQVimenVCTp+MLtOOS4wj3jTv4QeKH2GApT"
      ];
      extraGroups = ["wheel" "docker" "networkmanager"];
    };
  };

  nix.settings.trusted-users = [
    "root"
    "amaddox"
  ];

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false; # Set to false to avoid password prompt
    extraConfig = ''
      amaddox ALL=(ALL:ALL) NOPASSWD: ALL
    '';
  };

  # Sops configuration
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/amaddox/.config/sops/age/keys.txt";
  # Secrets
  sops.secrets.ts-authkey = {};

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}
