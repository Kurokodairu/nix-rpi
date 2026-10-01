{
  description = "kuro-rpi — portable Raspberry Pi 4B homelab sidekick (NixOS)";

  inputs = {
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    # Use the exact nixpkgs nixos-raspberrypi is built and cached against,
    # so everything hits nixos-raspberrypi.cachix.org instead of compiling.
    nixpkgs.follows = "nixos-raspberrypi/nixpkgs";

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
    sops-nix,
    ...
  }@inputs:
  let
    rpi = self.nixosConfigurations.rpi;
  in
  {
    nixosConfigurations.rpi =
      nixos-raspberrypi.lib.nixosSystem {
        specialArgs = inputs;
        modules = [
          { _module.args.self = self; }

          # RPi4 hardware
          nixos-raspberrypi.nixosModules.raspberry-pi-4.base
          nixos-raspberrypi.nixosModules.raspberry-pi-4.display-vc4
          nixos-raspberrypi.nixosModules.raspberry-pi-4.bluetooth
          # Partition layout + image builder (labels: FIRMWARE / NIXOS_SD).
          # The same image works on an SD card or a USB SSD/stick.
          nixos-raspberrypi.nixosModules.sd-image

          # Sops
          sops-nix.nixosModules.sops

          # config
          ./configuration.nix
          ./hardware.nix
          ./modules/first-boot.nix
          ./modules/power.nix
          ./modules/networking.nix
          ./modules/usb-gadget.nix
          ./modules/storage.nix
          ./modules/avahi.nix
          ./modules/ssh.nix
          ./modules/users.nix
          ./modules/homelab.nix
          ./modules/wireguard.nix
          ./modules/packages.nix
          ./modules/auto-deploy.nix
        ];
      };

    # Flashable image: `nix build .#image` (needs aarch64 builder or binfmt)
    packages.aarch64-linux.image = rpi.config.system.build.sdImage;
    packages.x86_64-linux.image = rpi.config.system.build.sdImage;
  };
}
