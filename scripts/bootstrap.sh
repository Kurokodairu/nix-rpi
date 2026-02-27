#!/usr/bin/env bash
set -euo pipefail

PI_HOST="${1:-kuro-rpi.local}"
REPO_URL="https://github.com/Kurokodairu/nix-rpi.git"
AGE_KEY="secrets/rpi.age"

echo ""
echo "========================================="
echo "  Kuro RPi — Bootstrap"
echo "========================================="
echo ""

# ── Preflight checks ──
if [ ! -f "$AGE_KEY" ]; then
  echo "ERROR: Age key not found at $AGE_KEY"
  echo "Run: age-keygen -o $AGE_KEY"
  exit 1
fi

echo "[1/5] Waiting for Pi at ${PI_HOST}..."
until ssh -o ConnectTimeout=5 \
         -o StrictHostKeyChecking=accept-new \
         "kuro@${PI_HOST}" 'echo ok' 2>/dev/null; do
  printf "  not ready, retrying in 5s...\r"
  sleep 5
done
echo "  Pi is online!                        "

echo "[2/5] Copying age key..."
ssh "kuro@${PI_HOST}" 'sudo mkdir -p /var/lib/sops-nix'
scp "$AGE_KEY" "kuro@${PI_HOST}":/tmp/age.key
ssh "kuro@${PI_HOST}" '
  sudo mv /tmp/age.key /var/lib/sops-nix/age.key
  sudo chmod 600 /var/lib/sops-nix/age.key
  sudo chown root:root /var/lib/sops-nix/age.key
'

echo "[3/5] Cloning config repo on Pi..."
ssh "kuro@${PI_HOST}" "
  sudo rm -rf /etc/nixos-config
  sudo git clone --branch main ${REPO_URL} /etc/nixos-config
"

echo "[4/5] Rebuilding NixOS (this takes a while)..."
echo "  The SSH connection may drop when networking switches."
echo "  This is normal — the Pi will reconnect on its own."
echo ""
ssh -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=3 \
    "kuro@${PI_HOST}" "
  sudo nixos-rebuild switch --flake /etc/nixos-config#rpi
" || true

echo ""
echo "[5/5] Waiting for Pi to come back..."
sleep 10
until ssh -o ConnectTimeout=5 \
         "kuro@${PI_HOST}" 'echo ok' 2>/dev/null; do
  printf "  reconnecting...\r"
  sleep 5
done

echo ""
echo "========================================="
echo "  Bootstrap complete!"
echo "========================================="
echo ""
ssh "kuro@${PI_HOST}" '
  echo "  Hostname : $(hostname)"
  echo "  Revision : $(cat /run/current-system/configuration-revision 2>/dev/null || echo N/A)"
  echo "  Uptime   : $(uptime -p)"
  echo "  Timer    : $(systemctl is-active auto-deploy.timer)"
'
echo ""
echo "Push to ${REPO_URL} and the Pi updates within 5 minutes."
echo "Manual trigger: ssh kuro@${PI_HOST} 'sudo systemctl start auto-deploy'"