# Shared Tailscale setup.
#
# - Tailscale SSH is enabled on every host that imports this, so `ssh <host>`
#   works over the tailnet without managing keys (access is governed by the
#   tailnet ACL "ssh" rules, not ~/.ssh/authorized_keys).
# - `extraSetFlags` is applied with `tailscale set` on every start, so it also
#   takes effect on nodes that are already logged in.
# - To have a fresh install join the tailnet unattended, a host can set
#   `services.tailscale.authKeyFile` (e.g. to a sops secret path).
{...}: {
  services.tailscale = {
    enable = true;
    # Opens Tailscale's UDP port (41641) so peers can connect directly instead of via DERP relays.
    openFirewall = true;
    extraSetFlags = ["--ssh"];
  };
}
