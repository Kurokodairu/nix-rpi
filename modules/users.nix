{ pkgs, ... }:

{
  users.users.kuro = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICXphSQAChtJmZW+yFb3wMf1vK99y/+NqnAsTUHmVY6g jsvendsli@gmail.com"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}