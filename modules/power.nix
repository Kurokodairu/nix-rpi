{ config, lib, pkgs, ... }:

let
  cfg = config.kuro.power;

  pi-status = pkgs.writeShellScriptBin "pi-status" ''
    export PATH=${lib.makeBinPath [ pkgs.raspberrypi-utils pkgs.procps pkgs.coreutils pkgs.gawk pkgs.iproute2 ]}:$PATH

    t=$(vcgencmd get_throttled 2>/dev/null | cut -d= -f2)
    t=$(( ''${t:-0} ))
    flag() { (( t & (1 << $1) )) && printf '%s' "$2"; }

    now="$(flag 0 'UNDER-VOLTAGE ')$(flag 1 'freq-capped ')$(flag 2 'THROTTLED ')$(flag 3 'temp-limit ')"
    past="$(flag 16 'under-voltage ')$(flag 17 'freq-capped ')$(flag 18 'throttled ')$(flag 19 'temp-limit ')"

    printf '  %-10s %s\n' \
      temp  "$(vcgencmd measure_temp | cut -d= -f2)" \
      cpu   "$(( $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) / 1000 )) MHz ($(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor))" \
      core  "$(vcgencmd measure_volts core | cut -d= -f2)" \
      power "''${now:-ok}''${past:+ (since boot: $past)}" \
      ip    "$(ip -4 -br addr | awk '$1 != "lo" && $3 {print $1"="$3}' | tr '\n' ' ')" \
      up    "$(uptime -p)"
    if (( t & 0x10001 )); then
      echo "  ! power supply sagging — use a 5V/3A PD powerbank + short thick cable, or set kuro.power.lowPower"
    fi
  '';
in
{
  options.kuro.power.lowPower = lib.mkEnableOption ''
    battery-friendly clocks (caps the CPU at 1.2 GHz). Use this when weak
    powerbanks/cables cause under-voltage warnings in `pi-status`
  '';

  config = {
    # Scale clocks with load instead of sitting at max. Set via the kernel
    # cmdline rather than powerManagement.cpuFreqGovernor, which pulls in
    # cpupower and a local kernel-config build.
    boot.kernelParams = [ "cpufreq.default_governor=ondemand" ];

    hardware.raspberry-pi.config.all = {
      options = {
        disable_splash = { enable = true; value = 1; };
        boot_delay = { enable = true; value = 0; };
        arm_freq = { enable = cfg.lowPower; value = 1200; };
        arm_boost = { enable = cfg.lowPower; value = 0; };
      };

      # Safe-shutdown "button": short pin 40 (GPIO21) to pin 39 (GND) to halt
      # cleanly before pulling the powerbank. GPIO3 isn't used because it is I2C SCL.
      dt-overlays.gpio-shutdown = {
        enable = true;
        params.gpio_pin = { enable = true; value = 21; };
      };
    };

    # Bluetooth is available for tinkering but off until you `bluetoothctl power on`
    hardware.bluetooth.powerOnBoot = false;

    environment.systemPackages = [ pi-status ];

    # Show a status line on interactive SSH logins (power, temp, IPs)
    programs.bash.interactiveShellInit = ''
      if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && [ "$SHLVL" -le 2 ]; then
        pi-status
      fi
    '';
  };
}
