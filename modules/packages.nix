{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    btop
    tmux
    wget
    curl
    usbutils
    pciutils
    jq
    ripgrep
    kitty.terminfo
    libgpiod
    (python3.withPackages (ps: [
      ps.gpiozero
      ps.lgpio
    ]))
  ];
}