{ ... }:

# Extra storage: the SD card slot (or any drive) formatted ext4 with label
# PISTORAGE shows up at /srv/storage. Optional — the Pi boots fine without it.
#
# Prepare a new card/drive (on the Pi):
#   sudo mkfs.ext4 -L PISTORAGE -E root_owner=1000:100 /dev/mmcblk0p1
#
# Never leave a card with FIRMWARE/NIXOS_SD labels in the slot: the Pi could
# boot or mount that instead of the USB drive.
{
  fileSystems."/srv/storage" = {
    device = "/dev/disk/by-label/PISTORAGE";
    fsType = "ext4";
    options = [
      "nofail" # boot normally when it's absent
      "noatime"
      "x-systemd.automount" # mounted on first access, doesn't slow boot
      "x-systemd.device-timeout=5s"
    ];
  };
}
