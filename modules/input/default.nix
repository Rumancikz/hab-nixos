{ config, pkgs, ... }:

{
  # Input device configuration
  services.libinput.enable = true;

  # Keyboard settings
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
}