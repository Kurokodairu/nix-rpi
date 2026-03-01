{ config, pkgs, lib, self, ... }:

{
  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/Oslo";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "kuro" ];
    substituters = [
    "https://cache.nixos.org"
    "https://nixos-raspberrypi.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  networking.hostName = "kuro-rpi";

  system.configurationRevision =
    self.rev or self.dirtyRev or "unknown";
}