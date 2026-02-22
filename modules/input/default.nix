{ config, pkgs, ... }:

{
  # Input device configuration
  services.xserver.libinput.enable = true;

  # Touchpad settings for laptop
  services.xserver.libinput.touchpad = {
    tapping = true;
    naturalScrolling = true;
    twoFingerScrolling = true;
    clickMethod = "fingers";
  };

  # Keyboard settings
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
}