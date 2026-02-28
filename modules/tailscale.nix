{ pkgs, ... }:

{
  services.tailscale.enable = true;

  # After first boot, authenticate with:
  #   sudo tailscale up --ssh
  # This also enables Tailscale SSH so you can
  # reach the Pi from anywhere on your tailnet.

  environment.systemPackages = [ pkgs.tailscale ];
}