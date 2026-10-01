{ lib, ... }:

# Plug the Pi's USB-C port into a laptop: the laptop powers the Pi AND gets a
# network link to it (DHCP from the Pi). Then: ssh kuro@10.55.0.1
# Works with no WiFi at all — the go-to way to reach it on the road.
{
  hardware.raspberry-pi.config.all.dt-overlays.dwc2 = {
    enable = true;
    params.dr_mode = { enable = true; value = "peripheral"; };
  };

  boot.kernelModules = [ "dwc2" "g_ether" ];
  # Fixed MACs so the laptop sees the same interface every time
  boot.extraModprobeConfig = ''
    options g_ether host_addr=02:6b:75:72:6f:01 dev_addr=02:6b:75:72:6f:02
  '';

  # Ignore the dead route when the cable is unplugged
  boot.kernel.sysctl."net.ipv4.conf.all.ignore_routes_with_linkdown" = 1;

  networking.networkmanager.ensureProfiles.profiles.usb-gadget = {
    connection = {
      id = "usb-gadget";
      type = "ethernet";
      interface-name = "usb0";
      autoconnect = "true";
    };
    # "shared" = Pi runs DHCP/DNS for the laptop on this link
    ipv4 = { method = "shared"; address1 = "10.55.0.1/24"; };
    ipv6.method = "link-local";
  };

  # Hand out addresses but no gateway/DNS, so the laptop keeps using its own
  # internet instead of routing everything through the Pi (also applies to
  # the fallback AP, which has no uplink anyway)
  environment.etc."NetworkManager/dnsmasq-shared.d/no-gateway.conf".text = ''
    dhcp-option=option:router
    dhcp-option=option:dns-server
  '';

  networking.firewall.trustedInterfaces = [ "usb0" ];
}
