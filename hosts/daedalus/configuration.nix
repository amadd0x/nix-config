{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  # Overlays, allowUnfree, flakes, registry, locale and OpenSSH come from
  # ../common/global.

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
