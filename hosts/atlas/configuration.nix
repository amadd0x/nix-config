{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # Overlays, allowUnfree, flakes, registry, locale, OpenSSH and auto-upgrade
  # defaults come from ../common/global; audio, printing and zsh from
  # ../common/optional/workstation.nix.

  nix.settings.download-buffer-size = 524288000;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Pulls this repo from GitHub daily (settings in ../common/global/auto-upgrade.nix).
  system.autoUpgrade.enable = true;

  ############
  # Services #
  ############

  # Docker itself is enabled in ../common/optional/dev.nix
  virtualisation.docker.daemon.settings = {
    insecure-registries = ["192.168.0.112:5000"];
  };

  # Cinnamon desktop
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
  };

  # The portal packages come from xdg.portal (Cinnamon adds the gtk and xapp
  # portals), so they aren't listed here or in extraPortals.
  environment.systemPackages = with pkgs; [
    xdg-utils
  ];

  services.envfs.enable = true;

  users.users.amaddox = {
    isNormalUser = true;
    description = "Austin Maddox";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
  };

  # Run appimages with a nix interpreter by default
  # https://nixos.wiki/wiki/Appimage
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

  # Crontab
  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 9 * * MON  amaddox /home/amaddox/workspace/scripts/automation/weekly-report/weekly-report.sh >> /home/amaddox/workspace/scripts/automation/weekly-report/logs/$(date +\%Y-\%m-\%d).log 2>&1"
    ];
  };

  # Sops configuration
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/amaddox/.config/sops/age/keys.txt";
  # Secrets
  sops.secrets.gmail-pass = {};
  sops.secrets.ovpn-user = {};
  sops.secrets.ovpn-pass = {};
  sops.secrets.ts-authkey = {};

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
