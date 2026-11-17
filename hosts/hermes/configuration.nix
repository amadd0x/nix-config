{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  # Overlays, allowUnfree, flakes, registry, locale and OpenSSH come from
  # ../common/global; audio, printing and zsh from ../common/optional/workstation.nix.

  # Lets `nixos-rebuild --target-host` from atlas copy unsigned store paths in.
  nix.settings.trusted-users = ["root" "amaddox"];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "hermes";
  networking.networkmanager.enable = true;

  # KDE Plasma desktop
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Firmware updates (BIOS/Thunderbolt/etc.) via `fwupdmgr`
  services.fwupd.enable = true;

  users.users.amaddox = {
    isNormalUser = true;
    description = "Austin Maddox";
    extraGroups = ["networkmanager" "wheel" "docker"];
    shell = pkgs.zsh;
    # Fallback for when Tailscale SSH is unavailable (atlas: ~/.ssh/daedalus).
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEKt24WTdgQVimenVCTp+MLtOOS4wj3jTv4QeKH2GApT"
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Sudo keeps its password on the laptop; remote deploys use --ask-sudo-password.

  programs.firefox.enable = true;

  system.stateVersion = "25.11"; # Fresh install; don't change after.
}
