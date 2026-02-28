{ config, pkgs, lib, self, ... }:

{
  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/Oslo";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
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