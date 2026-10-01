{ config, ... }:

# Optional plain WireGuard tunnel to the homelab (Tailscale in homelab.nix
# usually covers this). To enable:
#   1. `sops secrets/secrets.yaml` and add `wireguard_private_key`
#   2. uncomment below
{
  # sops.secrets.wireguard_private_key = {};
  #
  # networking.wg-quick.interfaces.wg0 = {
  #   address = [ "10.0.0.2/24" ];
  #   privateKeyFile = config.sops.secrets.wireguard_private_key.path;
  #   peers = [
  #     {
  #       publicKey = "YOUR_SERVER_PUBLIC_KEY";
  #       endpoint = "your.server.ip:51820";
  #       allowedIPs = [ "10.0.0.0/24" ];
  #       persistentKeepalive = 25;
  #     }
  #   ];
  # };
}
