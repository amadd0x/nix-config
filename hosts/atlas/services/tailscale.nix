{
  lib,
  pkgs,
  ...
}: {
  services.tailscale.enable = true;
  systemd.services.tailscale-autoconnect = {
    description = "Automatically connect to Tailscale";
    after = ["network-pre.target" "tailscale.service"];
    wants = ["network-pre.target" "tailscale.service"];
    wantedBy = ["multi-user.target"];
    # Set this service as a oneshot job
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      # Allow Tailscale to settle
      sleep 2
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then
        exit 0
      fi
      # ${tailscale}/bin/tailscale up -authkey $(cat /run/secrets/ts-authkey)
    '';
  };
}
