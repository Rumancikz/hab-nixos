{ config, pkgs, ... }:

{
  # Input device configuration
  services.xserver.libinput.enable = true;

  # Keyboard settings
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
}