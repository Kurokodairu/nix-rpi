{ config, pkgs, ... }:

let
  repoUrl = "https://github.com/Kurokodairu/nix-rpi.git";
  repoBranch = "main";
  repoDir = "/etc/nixos-config";
  stateDir = "/var/lib/auto-deploy";

  deployScript = pkgs.writeShellScript "auto-deploy" ''
    set -euo pipefail

    export PATH="${pkgs.lib.makeBinPath [
      pkgs.git
      pkgs.nix
      pkgs.nixos-rebuild
      pkgs.systemd
      pkgs.coreutils
    ]}"

    echo "Auto-deploy check: $(date)"

    if [ ! -d "${repoDir}/.git" ]; then
      echo "Cloning repo..."
      git clone --branch ${repoBranch} ${repoUrl} ${repoDir}
    fi

    cd ${repoDir}
    git fetch origin ${repoBranch}

    # Compare against what was last *successfully* deployed, not the checkout,
    # so a failed build is retried on the next run instead of being skipped
    DEPLOYED=$(cat ${stateDir}/deployed-rev 2>/dev/null || echo none)
    BAD=$(cat ${stateDir}/bad-rev 2>/dev/null || echo none)
    REMOTE=$(git rev-parse origin/${repoBranch})

    if [ "$DEPLOYED" = "$REMOTE" ]; then
      echo "No changes. Current: ''${REMOTE:0:8}"
      exit 0
    fi
    if [ "$BAD" = "$REMOTE" ]; then
      echo "''${REMOTE:0:8} was rolled back earlier; waiting for a new commit"
      exit 0
    fi

    echo "Update found: ''${DEPLOYED:0:8} -> ''${REMOTE:0:8}"
    git reset --hard origin/${repoBranch}

    echo "Rebuilding NixOS..."
    nixos-rebuild switch --flake "${repoDir}#rpi"

    # Health check: if the new config cut us off from the network, undo it
    sleep 20
    if ! git ls-remote --exit-code origin ${repoBranch} >/dev/null 2>&1 \
       || ! systemctl is-active --quiet sshd; then
      echo "Health check FAILED after deploying ''${REMOTE:0:8} — rolling back"
      echo "$REMOTE" > ${stateDir}/bad-rev
      nixos-rebuild switch --rollback
      exit 1
    fi

    echo "$REMOTE" > ${stateDir}/deployed-rev
    echo "Deploy complete at: ''${REMOTE:0:8}"

    # Reboot if kernel changed
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
    # Never let a deploy that switches networking kill itself mid-way
    restartIfChanged = false;

    serviceConfig = {
      Type = "oneshot";
      ExecStart = deployScript;
      StateDirectory = "auto-deploy";
      TimeoutStartSec = "1h";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.auto-deploy = {
    description = "Poll GitHub for config changes";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "15min";
      RandomizedDelaySec = "1min";
    };
  };
}
