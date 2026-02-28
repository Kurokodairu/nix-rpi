{
  description = "RPi - NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  outputs = {
    self,
    nixpkgs,
    nixos-raspberrypi,
    ...
  }@inputs:
  {
    nixosConfigurations.rpi =
      nixos-raspberrypi.lib.nixosSystem {
        specialArgs = inputs;
        modules = [
          { _module.args.self = self; }

          # RPi4 hardware
          nixos-raspberrypi.nixosModules.raspberry-pi-4.base
          nixos-raspberrypi.nixosModules.raspberry-pi-4.display-vc4

          # config
          ./configuration.nix
          ./hardware.nix
          ./modules/avahi.nix
          ./modules/ssh.nix
          ./modules/users.nix
          ./modules/wireguard.nix
          ./modules/packages.nix
          ./modules/auto-deploy.nix
          ./modules/networking.nix
        ];
      };
  };
}