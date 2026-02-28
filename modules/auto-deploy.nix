{ config, pkgs, ... }:

let
  repoUrl = "https://github.com/Kurokodairu/nix-rpi.git";
  repoBranch = "main";
  repoDir = "/etc/nixos-config";

  deployScript = pkgs.writeShellScript "auto-deploy" ''
    set -euo pipefail

    export PATH="${pkgs.lib.makeBinPath [
      pkgs.git
      pkgs.nix
      pkgs.nixos-rebuild
      pkgs.systemd
      pkgs.coreutils
    ]}"

    LOGFILE="/var/log/auto-deploy.log"
    exec >> "$LOGFILE" 2>&1
    echo "────────────────────────────────────────"
    echo "Auto-deploy check: $(date)"

    if [ ! -d "${repoDir}/.git" ]; then
      echo "Cloning repo..."
      git clone --branch ${repoBranch} ${repoUrl} ${repoDir}
    fi

    cd ${repoDir}
    git fetch origin ${repoBranch}

    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/${repoBranch})

    if [ "$LOCAL" = "$REMOTE" ]; then
      echo "No changes. Current: ''${LOCAL:0:8}"
      exit 0
    fi

    echo "Update found: ''${LOCAL:0:8} -> ''${REMOTE:0:8}"
    git reset --hard origin/${repoBranch}

    echo "Rebuilding NixOS..."
    nixos-rebuild switch --flake "${repoDir}#rpi" 2>&1

    echo "Deploy complete at: $(git rev-parse --short HEAD)"

    booted=$(readlink /run/booted-system/kernel 2>/dev/null || echo "")
    current=$(readlink /run/current-system/kernel 2>/dev/null || echo "")
    if [ -n "$booted" ] && [ "$booted" != "$current" ]; then
      echo "Kernel changed — rebooting in 1 minute"
      shutdown -r +1 "NixOS auto-deploy: kernel updated"
    fi
  '';
in
{
  environment.etc."gitconfig".text = ''
    [safe]
      directory = ${repoDir}
  '';

  systemd.services.auto-deploy = {
    description = "NixOS GitOps auto-deploy";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = deployScript;
      TimeoutStartSec = "10min";
    };
  };

  systemd.timers.auto-deploy = {
    description = "Poll GitHub for config changes";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
      RandomizedDelaySec = "30s";
    };
  };

  services.logrotate.settings.auto-deploy = {
    files = [ "/var/log/auto-deploy.log" ];
    frequency = "weekly";
    rotate = 4;
    compress = true;
    missingok = true;
  };
}