{ pkgs, ... }:

{
  users.users.kuro = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "gpio" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICXphSQAChtJmZW+yFb3wMf1vK99y/+NqnAsTUHmVY6g jsvendsli@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDfys3+HdOzWU4GuIEhvDx2qceOxK2Y+pSUvCQFHRjrM jsvendsli@gmail.com"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}