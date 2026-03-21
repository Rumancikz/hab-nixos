# Main configuration for glacier desktop
# Build commands:
#   Local build:  nixos-rebuild switch --flake .#glacier
#   Remote build: nixos-rebuild switch --flake .#glacier --target-host zman@<glacier-ip>
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./hardware-configuration.nix

    # Dendritic module structure
    ../../modules/disk/zfs.nix

    ../../modules/networking/bluetooth.nix
    ../../modules/networking/wifi.nix
    ../../modules/networking/tailscale.nix

    ../../modules/desktop/plasma6-xserver.nix
    # NOTE: No Hyprland on glacier

    ../../modules/users/zman/zman.nix

    ../../modules/apps/default.nix
    ../../modules/services/ai-cuda.nix        # CUDA variant
    ../../modules/packages-override-cuda.nix  # CUDA variant
  ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "glacier";
  networking.hostId = "69beefd1";  # Must be unique for ZFS
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # NVIDIA GPU support
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  system.stateVersion = "24.11";
}
