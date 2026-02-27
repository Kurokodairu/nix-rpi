{ ... }:

{
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.kernelParams = [ "console=ttyS1,115200n8" ];

  hardware.raspberry-pi."4".fkms-3d.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/swapfile"; size = 2048; }
  ];
}