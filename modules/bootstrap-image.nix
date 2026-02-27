{ pkgs, lib, ... }:

{
  # Override: use wpa_supplicant, not NetworkManager
  networking.networkmanager.enable = lib.mkForce false;

  networking.wireless = {
    enable = true;
    networks = {
      "Waifu5Ghz" = {
        pskRaw = "2d060ad03c76a24720c055dfb7c5cda9c1e58031a5a21ee519d46e0f0905fa0e";
      };
      # Optional fallback: phone hotspot
      "Nothing" = {
        pskRaw = "d74cdff0f465eac72f631a521f07ac16621b2772a7d0f2c1663e33d311651789";
      };
    };
  };

  networking.interfaces.wlan0.useDHCP = true;

  # Make sure SSH starts no matter what
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];

  # Skip sops on first boot (no age key yet)
  sops.validateSopsFiles = false;

  environment.etc."motd".text = ''

    =============================================
      Kuro RPi - BOOTSTRAP MODE
      
      Run bootstrap.sh from your main machine
      to install secrets and switch to full config.
    =============================================

  '';
}