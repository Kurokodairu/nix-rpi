{ ... }:

{
  # NetworkManager handles both ethernet and WiFi
  # After first boot, configure WiFi with:
  #   sudo nmcli device wifi connect "YourSSID" password "YourPassword"
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    # Tailscale manages its own firewall rules
    trustedInterfaces = [ "tailscale0" ];
  };
}