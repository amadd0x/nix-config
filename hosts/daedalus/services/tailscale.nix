{config, ...}: {
  imports = [../../common/optional/tailscale.nix];

  # Join the tailnet unattended on a fresh install (only used when logged out).
  services.tailscale.authKeyFile = config.sops.secrets.ts-authkey.path;
}
