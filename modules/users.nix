{ pkgs, ... }:

{
  users.users.kuro = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      # REPLACE with your actual public key:
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcEyegEDKVm0UPOCBAVlyxu162NekqBWNicKqLhQuQc jsven@BLADE"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}