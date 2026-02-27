{ pkgs, ... }:

{
  # mDNS — makes kuro-rpi.local work on the network
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  networking.firewall.allowedUDPPorts = [ 5353 ];
}