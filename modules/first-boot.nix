{ pkgs, ... }:

# Zero-touch first boot: copy the sops age key onto the FIRMWARE partition
# (FAT, writable from any PC) as `age.key` after flashing. On boot it is moved
# to /var/lib/sops-nix, deleted from FAT, and secrets are (re)installed before
# NetworkManager starts — so WiFi works on the very first boot.
{
  systemd.services.age-key-import = {
    description = "Import sops age key from the FIRMWARE partition";
    wantedBy = [ "multi-user.target" ];
    before = [ "NetworkManager.service" "NetworkManager-ensure-profiles.service" ];
    # Pull in the real mount (not the automount) to avoid automount deadlocks
    unitConfig.RequiresMountsFor = "/boot/firmware";

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [ pkgs.coreutils pkgs.systemd ];
    script = ''
      src=/boot/firmware/age.key
      [ -f "$src" ] || exit 0

      install -D -m 600 -o root -g root "$src" /var/lib/sops-nix/age.key
      shred -u "$src" 2>/dev/null || rm -f "$src"
      sync
      echo "age key imported, installing secrets"
      systemctl restart sops-install-secrets.service
    '';
  };
}
