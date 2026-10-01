{ config, lib, ... }:

# Homelab sidekick: reachable from anywhere via Tailscale, scrapeable by
# Prometheus. One-time setup on the Pi: `sudo tailscale up --ssh`
# (or add a `tailscale_authkey` secret and set services.tailscale.authKeyFile).
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Can act as subnet router / exit node (e.g. advertise a travel LAN)
    useRoutingFeatures = "both";
  };

  # Node metrics on :9100 — only reachable over tailscale/usb0, never on
  # whatever café WiFi the Pi is sitting on
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    openFirewall = false;
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    # Tailscale + NM-managed WiFi: avoid strict rpfilter dropping exit-node traffic
    checkReversePath = "loose";
  };
}
