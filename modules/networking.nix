{ config, pkgs, lib, ... }:

let
  cfg = config.kuro.wifi;
  envName = name: "PSK_" + lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] name);
in
{
  options.kuro.wifi = {
    networks = lib.mkOption {
      description = ''
        Known WiFi networks. Each `secret` must exist in secrets/secrets.yaml
        (add it with `sops secrets/secrets.yaml`) before you add the network
        here. Raw 64-hex PSKs (wpa_passphrase output) work too.
      '';
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          ssid = lib.mkOption { type = lib.types.str; };
          secret = lib.mkOption { type = lib.types.str; };
          priority = lib.mkOption { type = lib.types.int; default = 0; };
        };
      });
      default = {};
    };

    fallbackAp = {
      enable = lib.mkEnableOption ''
        a WiFi access point ("<hostname>", 10.56.0.1) when no known network
        is in range ~2 min after boot. Needs the `ap_password` secret
      '';
      ssid = lib.mkOption { type = lib.types.str; default = config.networking.hostName; };
    };
  };

  config = {
    kuro.wifi.networks = {
      home = { ssid = "Waifu6.7Ghz"; secret = "wifi_password"; priority = 100; };
      # Phone hotspot for when you're out. Add `wifi_phone_psk` with sops first:
      # phone = { ssid = "Nothing"; secret = "wifi_phone_psk"; priority = 50; };
    };

    networking.networkmanager = {
      enable = true;
      # brcmfmac power save causes dropped/laggy SSH; the saving is tiny
      wifi.powersave = false;

      ensureProfiles = {
        environmentFiles = [ config.sops.templates."nm-wifi.env".path ];
        profiles = lib.mapAttrs (name: net: {
          connection = {
            id = name;
            type = "wifi";
            autoconnect = "true";
            autoconnect-priority = toString net.priority;
          };
          wifi = { ssid = net.ssid; mode = "infrastructure"; };
          wifi-security = { key-mgmt = "wpa-psk"; psk = "$" + envName name; };
          ipv4.method = "auto";
          ipv6.method = "auto";
        }) cfg.networks // lib.optionalAttrs cfg.fallbackAp.enable {
          fallback-ap = {
            connection = {
              id = "fallback-ap";
              type = "wifi";
              interface-name = "wlan0";
              autoconnect = "false";
            };
            wifi = { ssid = cfg.fallbackAp.ssid; mode = "ap"; band = "bg"; };
            wifi-security = { key-mgmt = "wpa-psk"; psk = "$PSK_AP"; };
            ipv4 = { method = "shared"; address1 = "10.56.0.1/24"; };
            ipv6.method = "disabled";
          };
        };
      };
    };
    # Don't touch networking.wireless: the NetworkManager module enables it
    # (dbus-controlled) to provide wpa_supplicant. Disabling it kills WiFi.

    sops.secrets = lib.genAttrs
      (lib.unique (lib.mapAttrsToList (_: n: n.secret) cfg.networks
        ++ lib.optional cfg.fallbackAp.enable "ap_password"))
      (_: {});

    sops.templates."nm-wifi.env".content = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: net:
        "${envName name}=${config.sops.placeholder.${net.secret}}") cfg.networks
      ++ lib.optional cfg.fallbackAp.enable
        "PSK_AP=${config.sops.placeholder.ap_password}"
    );

    # Profiles must be (re)written after secrets are decrypted
    systemd.services.NetworkManager-ensure-profiles = {
      after = [ "sops-install-secrets.service" ];
      wants = [ "sops-install-secrets.service" ];
    };

    systemd.services.wifi-fallback-ap = lib.mkIf cfg.fallbackAp.enable {
      description = "Start fallback access point if no WiFi is connected";
      path = [ pkgs.networkmanager ];
      serviceConfig.Type = "oneshot";
      script = ''
        if nmcli -t -f DEVICE,STATE device | grep -q '^wlan0:connected'; then
          echo "wlan0 connected, no AP needed"
        else
          echo "no known WiFi, starting fallback AP"
          nmcli connection up fallback-ap
        fi
      '';
    };
    systemd.timers.wifi-fallback-ap = lib.mkIf cfg.fallbackAp.enable {
      wantedBy = [ "timers.target" ];
      timerConfig.OnBootSec = "2min";
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      # DHCP + DNS for clients of the fallback AP (dnsmasq only runs in AP mode)
      interfaces.wlan0 = lib.mkIf cfg.fallbackAp.enable {
        allowedUDPPorts = [ 53 67 ];
        allowedTCPPorts = [ 53 ];
      };
    };
  };
}
