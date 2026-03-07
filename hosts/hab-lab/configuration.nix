# Main configuration for hab-lab-1 home lab server
# Build commands:
#   Local build:  nixos-rebuild switch --flake .#hab-lab
#   Remote build: nixos-rebuild switch --flake .#hab-lab --target-host hab-lab@10.0.0.6 --use-remote-sudo
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
    
    # Dendritic module structure
    ../../modules/disk/default.nix
    ../../modules/networking/tailscale.nix
    ../../modules/services/serverdefault.nix
  ];

  # Boot configuration
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.supportedFilesystems = [ "zfs" "btrfs" ];
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

    networking = {
    hostId = "007f0201";
    hostName = "hab-lab-1";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        8080
        config.services.firefly-iii.settings.DB_PORT
        config.services.mealie.port
      ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Services
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    ports = [ 22 ];
  };

  services.fail2ban.enable = true;

  # System packages
  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  # Time and locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Users
  users = {
    mutableUsers = false;
    users = {
      root = {
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGobqsOAomSQvVfN/I0TQlqTMcD/W4h3W6/9taeLeC4Sx4XtcPZRNfrfeNeBfgCsEt4VZtjFOnZPAbqPOOpmQC44K5a9OBxDakhiWLdJlOMFlBxtW25TOny62ow7/qPVTsTInfT7RgGJ5zg/zIm0/92DEZJ4zihJSk3QbToX+vo+llWb9OaJMFiKdXgMGGOfufvX17bKWFop5CVgTKczw+GbNKzvne4oPXjw7WOF8egeJBnqQdDKj9qy/6Emoc9lLeK/TBsxEy71TkIT5xhBOlf1l9gZo+laBE5KK/3rSbPyTMMev0nejsxO4PtL757uzcgW21VGV2ZVFXgLx3Xd+uPvM4wadd8HCz5w2t+ugHh8mu0OBMvK/PjSQQxLozRxdcZEOy+wqnk5OrCYSfpx18gJa/RjgGe2EkgPRlvLRfi2dr47eCUrYUs7RZfod7XRjhauFaeG4dEgCApojGLJ6WNi0IwwzbjTQ7fzAJMalnF4f7alb1OrW28opZmhFmCF0= zach5@Glacier"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILepe2FGl5nzpyRWcHkRO8CPDygovL80Qik+HV8ypBAN zman@warframe"
        ];
        initialHashedPassword = "$y$j9T$RbcN4mdZop6gD9K4x07AH/$XKRWxzJnp8gJM3UF/W8p8DwvC4EADEAsvxFU0KDCbw7";
      };
      hab-lab = {
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGobqsOAomSQvVfN/I0TQlqTMcD/W4h3W6/9taeLeC4Sx4XtcPZRNfrfeNeBfgCsEt4VZtjFOnZPAbqPOOpmQC44K5a9OBxDakhiWLdJlOMFlBxtW25TOny62ow7/qPVTsTInfT7RgGJ5zg/zIm0/92DEZJ4zihJSk3QbToX+vo+llWb9OaJMFiKdXgMGGOfufvX17bKWFop5CVgTKczw+GbNKzvne4oPXjw7WOF8egeJBnqQdDKj9qy/6Emoc9lLeK/TBsxEy71TkIT5xhBOlf1l9gZo+laBE5KK/3rSbPyTMMev0nejsxO4PtL757uzcgW21VGV2ZVFXgLx3Xd+uPvM4wadd8HCz5w2t+ugHh8mu0OBMvK/PjSQQxLozRxdcZEOy+wqnk5OrCYSfpx18gJa/RjgGe2EkgPRlvLRfi2dr47eCUrYUs7RZfod7XRjhauFaeG4dEgCApojGLJ6WNi0IwwzbjTQ7fzAJMalnF4f7alb1OrW28opZmhFmCF0= zach5@Glacier"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILepe2FGl5nzpyRWcHkRO8CPDygovL80Qik+HV8ypBAN zman@warframe"
        ];
        initialHashedPassword = "$y$j9T$RbcN4mdZop6gD9K4x07AH/$XKRWxzJnp8gJM3UF/W8p8DwvC4EADEAsvxFU0KDCbw7";
        isNormalUser = true;
        extraGroups = [ "video" "render" "wheel" ];
      };
    };
  };

  # System configuration
  system.stateVersion = "24.05";
}