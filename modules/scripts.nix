{ pkgs, ... }:

# Adds custom scripts to PATH

let
  scripts = pkgs.stdenv.mkDerivation {
    name = "rpi-scripts";
    src = ../scripts;
    installPhase = ''
      mkdir -p $out/bin
      cp -r * $out/bin/
      chmod +x $out/bin/*
    '';
  };
in
{
  environment.systemPackages = [ scripts ];
}