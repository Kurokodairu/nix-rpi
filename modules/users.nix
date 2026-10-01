{ pkgs, ... }:

{
  users.users.kuro = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      # hardware tinkering without sudo
      "video" # vcgencmd, camera
      "gpio"
      "i2c"
      "spi"
      "dialout" # serial adapters
      "plugdev"
      "input"
    ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcEyegEDKVm0UPOCBAVlyxu162NekqBWNicKqLhQuQc jsven@BLADE" # Windows desktop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICXphSQAChtJmZW+yFb3wMf1vK99y/+NqnAsTUHmVY6g jsvendsli@gmail.com" # laptop
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
