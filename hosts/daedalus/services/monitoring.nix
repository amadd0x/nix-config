{...}: {
  # Host metrics for the prometheus nomad job (nomad-jobs/prometheus.nomad.hcl).
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = ["systemd"];
    # Not openFirewall: that opens 9100 to the whole LAN.
  };

  # Prometheus runs in a nomad bridge-mode allocation, so its scrapes of the
  # host IP arrive on the `nomad` bridge. Open 9100 there only.
  networking.firewall.interfaces.nomad.allowedTCPPorts = [9100];
}
