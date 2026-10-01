#!/usr/bin/env bash
# Build the image, write it to a USB SSD/stick (or SD card), and drop the sops
# age key on the FIRMWARE partition so the Pi joins WiFi on first boot.
#
#   scripts/flash.sh /dev/sdX
set -euo pipefail

DEV="${1:-}"
AGE_KEY="secrets/rpi.age"
export NIX_CONFIG="experimental-features = nix-command flakes"

cd "$(dirname "$0")/.."

if [ -z "$DEV" ] || [ ! -b "$DEV" ]; then
  echo "usage: $0 /dev/sdX   (whole disk, not a partition)"
  echo
  lsblk -d -o NAME,SIZE,MODEL,TRAN,RM
  exit 1
fi
if [ ! -f "$AGE_KEY" ]; then
  echo "ERROR: $AGE_KEY not found (the Pi's sops age key, see README)"
  exit 1
fi
if lsblk -no MOUNTPOINT "$DEV" | grep -qx '/'; then
  echo "ERROR: $DEV holds your running system"
  exit 1
fi

echo "[1/4] Building image..."
nix build .#image --out-link result-image --max-jobs auto
IMG=$(echo result-image/sd-image/*.img*)

echo
lsblk -o NAME,SIZE,MODEL,TRAN,LABEL,MOUNTPOINT "$DEV"
read -rp "ERASE EVERYTHING on $DEV and flash $(basename "$IMG")? type YES: " ok
[ "$ok" = "YES" ] || { echo "aborted"; exit 1; }

img_cat() {
  case "$IMG" in
    *.zst) zstdcat "$IMG" ;;
    *) cat "$IMG" ;;
  esac
}

echo "[2/4] Flashing..."
for p in $(lsblk -nlo PATH "$DEV" | tail -n +2); do sudo umount "$p" 2>/dev/null || true; done
img_cat | sudo dd of="$DEV" bs=4M conv=fsync status=progress

# Read everything back straight from the drive (bypassing the page cache).
# Cheap/fake-capacity sticks silently corrupt data; catch that here instead
# of debugging a Pi whose binaries are garbage.
echo "Verifying written data..."
res=$(img_cat | cmp - <(sudo dd if="$DEV" bs=4M iflag=direct status=none) 2>&1 || true)
case "$res" in
  *"EOF on -"*) echo "  verify OK" ;;
  *)
    echo "  VERIFY FAILED: $res"
    echo "  This drive does not store data reliably (failing or fake-capacity). Use another one."
    exit 1
    ;;
esac
sudo partprobe "$DEV" 2>/dev/null || true
sleep 2

echo "[3/4] Installing age key on FIRMWARE partition..."
FW=$(lsblk -nlo PATH,LABEL "$DEV" | awk '$2=="FIRMWARE"{print $1}')
MNT=$(mktemp -d)
sudo mount "$FW" "$MNT"
sudo cp "$AGE_KEY" "$MNT/age.key"
sudo umount "$MNT"
rmdir "$MNT"
sync

echo "[4/4] Done."
cat <<EOF

  Plug the drive into a *blue* USB 3 port, remove any SD card, power on.
  First boot takes ~1-2 min (root partition grows, secrets install).

    ssh kuro@kuro-rpi.local          # on the home WiFi
    ssh kuro@10.55.0.1               # USB-C cable to a laptop

  Then once: sudo tailscale up --ssh
EOF
