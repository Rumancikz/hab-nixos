{ config, pkgs, ... }:

{
  # Enable KDE Plasma 6 desktop environment
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.printing.enable = true;

  # Audio support in desktop environment
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
    # Keyboard settings
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Input device configuration
  services.libinput.enable = true;

}