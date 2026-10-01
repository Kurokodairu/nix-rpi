# kuro-rpi

NixOS for a Raspberry Pi 4B that is both a **homelab sidekick** (Tailscale,
Prometheus metrics, GitOps auto-deploy) and a **portable tinkering box** that
boots from USB and runs off a powerbank.

Built on [nvmd/nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi)
(vendor kernel/firmware, binary cache, declarative `config.txt`).

## Layout

| File | What |
|---|---|
| `flake.nix` | `nixosConfigurations.rpi` + `packages.*.image` (flashable `.img.zst`) |
| `hardware.nix` | firmware "kernel" bootloader (native USB boot), zram, fstrim |
| `modules/first-boot.nix` | imports `age.key` from the FIRMWARE partition on first boot |
| `modules/networking.nix` | NetworkManager WiFi from sops, optional fallback AP |
| `modules/usb-gadget.nix` | USB-C ethernet: laptop powers the Pi and gets `10.55.0.1` |
| `modules/power.nix` | ondemand governor, `pi-status`, shutdown pin, `kuro.power.lowPower` |
| `modules/homelab.nix` | Tailscale (subnet router/exit node capable), node-exporter :9100 |
| `modules/packages.nix` | I2C/SPI on, GPIO/serial/network tools, podman |
| `modules/auto-deploy.nix` | pulls `main` every 15 min, rebuilds, rolls back if it loses network |

## First install (USB boot)

1. **USB boot on the EEPROM.** Any Pi 4 bootloader from late 2020 or newer
   boots USB automatically when no SD card is inserted. To check or update the
   bootloader, flash *Raspberry Pi Imager → Misc utility images → Bootloader → USB Boot*
   to an SD card, boot it once (green LED blinks steadily), then remove it.
   Later you can check it from NixOS with `vcgencmd bootloader_version` and
   `vcgencmd bootloader_config` (`BOOT_ORDER=0xf14` = USB first).
2. **Building on x86** needs aarch64 emulation (`extra-platforms = aarch64-linux`
   + qemu binfmt; on NixOS, `boot.binfmt.emulatedSystems = [ "aarch64-linux" ];`).
   Almost everything comes from the cache.
3. **Flash:** `scripts/flash.sh /dev/sdX`. This builds the image, writes it, and copies
   `secrets/rpi.age` to the FIRMWARE partition as `age.key`.
4. Plug the drive into a **blue USB 3 port**, power on, then
   `ssh kuro@kuro-rpi.local` and run `sudo tailscale up --ssh` once.

The root partition grows to fill the drive on first boot. The image works the
same on an SD card.

> Migrating an existing SD install in place: this config switches the
> bootloader from U-Boot to `kernel`. Reflashing is the clean path.

## Secrets

`secrets/rpi.age` (git-ignored) is the Pi's age key. Edit secrets with:

```sh
nix shell nixpkgs#sops -c sops secrets/secrets.yaml
```

| Key | Used by |
|---|---|
| `wifi_password` | home WiFi (`kuro.wifi.networks.home`) |
| `wifi_phone_psk` | *(optional)* phone hotspot; then uncomment `phone` in `networking.nix` |
| `ap_password` | *(optional)* `kuro.wifi.fallbackAp.enable = true;` |
| `wireguard_private_key` | *(optional)* see `modules/wireguard.nix` |

Only declare secrets that exist in the file. A missing key makes sops fail to
install **all** secrets.

## Taking it with you

Ways in, from most to least reliable:

- **USB-C to a laptop:** the laptop powers the Pi and you `ssh kuro@10.55.0.1`.
  The laptop keeps its own internet (no gateway is advertised).
  The port must supply enough current (most USB-C laptop ports manage ~1.5–3 A;
  heavy USB loads on the Pi may brown out).
- **Phone hotspot:** add it as a known network (see Secrets).
- **Fallback AP:** if no known WiFi is around 2 min after boot, the Pi
  becomes its own access point `kuro-rpi` (`ssh kuro@10.56.0.1`).
- **Tailscale:** reachable as `kuro-rpi` from anywhere once it is online.

## Powerbank notes

- The Pi 4 wants **5.1 V / 3 A**. Use a USB-C PD powerbank and a short, thick
  cable. Cheap cables are the #1 cause of under-voltage.
- `pi-status` (also shown on SSH login) decodes `vcgencmd get_throttled`.
  If it reports under-voltage, set `kuro.power.lowPower = true;` (caps the
  CPU at 1.2 GHz) or power any USB SSD from a powered hub.
- Some powerbanks switch off at low load. If yours cuts out at idle, use
  one with an "always on" / low-current mode.
- **Shut down before unplugging:** `sudo poweroff`, or short pin 40 (GPIO21)
  to pin 39 (GND) with a button or jumper.

## Day-to-day

```sh
git push                                            # Pi deploys within ~15 min
ssh kuro@kuro-rpi 'sudo systemctl start auto-deploy'  # deploy now
ssh kuro@kuro-rpi 'journalctl -u auto-deploy -e'      # deploy log
nixos-rebuild switch --flake .#rpi --target-host kuro@kuro-rpi --sudo  # push from laptop
```

A deploy that breaks networking or SSH is rolled back automatically, and that
commit is skipped until a newer one lands.
