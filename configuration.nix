{ config, pkgs, lib, self, ... }:

{
  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];
    # 4 cores but little RAM: don't let builds starve SSH
    max-jobs = 2;
  };
  # Builds (auto-deploy) run at idle priority so the Pi stays responsive
  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # The NixOS manual is slow to build under emulation and useless on the Pi
  documentation.nixos.enable = false;

  networking.hostName = "kuro-rpi";

  # sops secret declarations
  # Only declare secrets that actually exist in secrets.yaml — a missing key
  # makes sops-install-secrets fail and *no* secrets get installed.
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/age.key";
    # Run as a systemd unit so first-boot.nix can re-run it after importing the key
    useSystemdActivation = true;

    secrets = {
      wifi_password = {};
    };
  };

  system.configurationRevision =
    self.rev or self.dirtyRev or "unknown";
}
