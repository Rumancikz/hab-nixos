{ config, pkgs, ... }:

{
  # Enable KDE Plasma 6 desktop environment
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;

  # Enable KDE applications
  environment.plasma6 = {
    enable = true;
  };

  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  services.printing.enable = true;
 

  # Audio support in desktop environment
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

}