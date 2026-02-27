{ config, pkgs, lib, ... }:

{
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # Write NM connection file with sops secret before NM starts
  systemd.services.nm-wifi-config = {
    description = "Inject WiFi credentials from sops into NetworkManager";
    before = [ "NetworkManager.service" ];
    requiredBy = [ "NetworkManager.service" ];
    unitConfig.ConditionPathExists = "/var/lib/sops-nix/age.key";

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      SECRET_PATH="${config.sops.secrets.wifi_password.path}"
      if [ ! -f "$SECRET_PATH" ]; then
        echo "WiFi secret not available yet, skipping"
        exit 0
      fi

      PASSWORD=$(cat "$SECRET_PATH")
      mkdir -p /etc/NetworkManager/system-connections

      cat > /etc/NetworkManager/system-connections/home.nmconnection << NMEOF
[connection]
id=home
type=wifi
autoconnect=true
autoconnect-priority=100

[wifi]
ssid=Waifu5Ghz
mode=infrastructure

[wifi-security]
key-mgmt=wpa-psk
psk=$PASSWORD

[ipv4]
method=auto

[ipv6]
method=auto
NMEOF

      chmod 600 /etc/NetworkManager/system-connections/home.nmconnection
      echo "WiFi config written successfully"
    '';
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };
}