{ pkgs, ... }:

{
  # GPIO header buses for sensors, displays, HATs
  hardware.raspberry-pi.config.all.base-dt-params = {
    i2c_arm = { enable = true; value = "on"; };
    spi = { enable = true; value = "on"; };
  };
  hardware.i2c.enable = true;

  # Containers without a daemon idling on battery; `docker` alias included
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  environment.systemPackages = with pkgs; [
    # basics
    vim
    git
    htop
    btop
    tmux
    wget
    curl
    jq
    ripgrep
    tree
    age
    sops

    # hardware
    usbutils
    pciutils
    i2c-tools
    libgpiod # gpiodetect / gpioget / gpioset
    picocom # serial consoles
    raspberrypi-eeprom # rpi-eeprom-config: check/tune USB boot order
    (python3.withPackages (ps: [ ps.gpiozero ps.lgpio ps.smbus2 ps.pyserial ]))

    # network tinkering
    wireguard-tools
    nmap
    iperf3
    mtr
    tcpdump
    ethtool
    dig
  ];
}
