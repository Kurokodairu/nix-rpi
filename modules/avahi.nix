{ ... }:

{
  # mDNS — makes kuro-rpi.local work on the network (and over the USB link)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
}
