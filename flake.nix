{
  description = "RPi - NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    sops-nix,
    ...
  }:
  let
    baseModules = [
      nixos-hardware.nixosModules.raspberry-pi-4
      sops-nix.nixosModules.sops
      { _module.args.self = self; }
      ./configuration.nix
      ./hardware.nix
      ./modules/avahi.nix
      ./modules/ssh.nix
      ./modules/users.nix
      ./modules/wireguard.nix
      ./modules/packages.nix
      ./modules/auto-deploy.nix
    ];
  in
  {
    # Running system (post-bootstrap, sops secrets)
    nixosConfigurations.rpi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = baseModules ++ [
        ./modules/networking.nix
      ];
    };

    # SD card image (pre-bootstrap, hardcoded WiFi)
    nixosConfigurations.rpi-image = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = baseModules ++ [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ./modules/bootstrap-image.nix
      ];
    };
  };
}