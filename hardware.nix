{ lib, ... }:

{
  # Firmware loads kernel+initrd straight from the FIRMWARE partition.
  # The Pi 4 EEPROM boots USB mass storage natively, so this avoids U-Boot's
  # flaky USB support and makes USB SSD boot just work. Each NixOS generation
  # lives in /boot/firmware/nixos/<gen>/ (see os_prefix in config.txt).
  boot.loader.raspberry-pi = {
    bootloader = "kernel";
    configurationLimit = 4;
  };

  # fileSystems "/" (label NIXOS_SD) and "/boot/firmware" (label FIRMWARE)
  # come from nixos-raspberrypi's sd-image module. Labels, not device paths,
  # so the same image boots from SD, USB stick or USB SSD.
  sdImage.compressImage = true;
  # Root partition grows to fill the drive on first boot
  sdImage.expandOnBoot = true;

  # USB boot drives
  boot.initrd.availableKernelModules = [ "uas" "usb_storage" ];
  # Some USB-SATA bridges misbehave with UAS on the Pi 4 (I/O errors, hangs).
  # If yours does, find its ID with `lsusb` and force plain usb-storage:
  # boot.kernelParams = [ "usb-storage.quirks=152d:0578:u" ];

  # The sd-image base profile enables ZFS; not needed, and it ties kernel
  # upgrades to ZFS compatibility
  boot.supportedFilesystems.zfs = lib.mkForce false;

  services.fstrim.enable = true;

  # Compressed RAM swap first, small swapfile as a backstop for big nix evals
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };
  swapDevices = [
    { device = "/swapfile"; size = 2048; priority = 1; }
  ];
  boot.kernel.sysctl."vm.swappiness" = 100; # prefer zram over dropping cache

  # Keep the journal small; flash doesn't need to hold weeks of logs
  services.journald.extraConfig = ''
    SystemMaxUse=200M
  '';
}
