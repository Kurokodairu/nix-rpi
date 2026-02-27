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
    wireguard-tools
    usbutils
    pciutils
    jq
    ripgrep
    age
    sops
  ];
}