{ config, pkgs, ... }:

{
  # Enable KDE Plasma 6 desktop environment
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Plasma 6 specific settings
  programs.kde = {
    enable = true;
    plasma5.enable = false;  # Disable Plasma 5, use Plasma 6
  };

  # Enable KDE applications
  environment.plasma6 = {
    enable = true;
    packages = with pkgs; [
      kdeApplications.kate
      kdeApplications.dolphin
      kdeApplications konsole
      kdeApplications.gwenview
      kdeApplications.kcalc
      kdeApplications.konqueror
    ];
  };

  # System settings
  services.xserver.displayManager.defaultSession = "plasma";

  # Enable touchpad support for laptops
  services.xserver.libinput.enable = true;

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