# Main configuration for hab-atlas — remote AI coding agent host
# Existing NixOS box (10.0.0.2) updated in place: no disko/disk-config,
# the machine keeps its current disk layout (ESP at /boot, ext4 root).
# Build commands:
#   Local build:  nixos-rebuild switch --flake .#hab-atlas
#   Remote build: nixos-rebuild switch --flake .#hab-atlas --target-host atlas@10.0.0.2 --use-remote-sudo
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Dendritic module structure
    ../../modules/networking/tailscale.nix
  ];

  # Boot configuration (UEFI + GRUB, in place)
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      useOSProber = true;
      efiSupport = true;
    };
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
  };
  boot.supportedFilesystems = [ "ext4" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [
    "root"
    "zman"
    "atlas"
  ];

  networking = {
    hostId = "007f0202";
    hostName = "hab-atlas";
    firewall = {
      # enable the firewall
      enable = true;
      # always allow traffic from your Tailscale network
      trustedInterfaces = [ "tailscale0" ];
      # allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [ config.services.tailscale.port ];
      # Tailscale DERP-over-TCP fallback (used when UDP is blocked)
      allowedTCPPorts = [ config.services.tailscale.port ];
    };
  };

  # allow unfree packages to be installed
  nixpkgs.config.allowUnfree = true;

  # Services
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = "no";
      # with UsePAM, keyboard-interactive falls back to password auth
      KbdInteractiveAuthentication = "no";
    };
  };

  services.fail2ban.enable = true;

  # System packages (tailscale itself comes from modules/networking/tailscale.nix)
  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  # Time and locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Rebuild rights for the atlas user (used by remote nixos-rebuild)
  security.sudo.extraRules = [{
    users = [ "atlas" ];
    commands = [
      {
        # Allows the user to switch the system to the new generation
        command = "/nix/var/nix/profiles/system/bin/switch-to-configuration";
        options = [ "NOPASSWD" ];
      }
      {
        # Allows the user to update the system profile link
        command = "/run/current-system/sw/bin/nix-env";
        options = [ "NOPASSWD" ];
      }
      {
        # Often required to verify the store or restart services
        command = "/run/current-system/sw/bin/systemctl";
        options = [ "NOPASSWD" ];
      }
    ];
  }];

  # Users
  users = {
    mutableUsers = false;
    users = {
      root = {
        initialHashedPassword = "$y$j9T$RbcN4mdZop6gD9K4x07AH/$XKRWxzJnp8gJM3UF/W8p8DwvC4EADEAsvxFU0KDCbw7";
      };
      atlas = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGobqsOAomSQvVfN/I0TQlqTMcD/W4h3W6/9taeLeC4Sx4XtcPZRNfrfeNeBfgCsEt4VZtjFOnZPAbqPOOpmQC44K5a9OBxDakhiWLdJlOMFlBxtW25TOny62ow7/qPVTsTInfT7RgGJ5zg/zIm0/92DEZJ4zihJSk3QbToX+vo+llWb9OaJMFiKdXgMGGOfufvX17bKWFop5CVgTKczw+GbNKzvne4oPXjw7WOF8egeJBnqQdDKj9qy/6Emoc9lLeK/TBsxEy71TkIT5xhBOlf1l9gZo+laBE5KK/3rSbPyTMMev0nejsxO4PtL757uzcgW21VGV2ZVFXgLx3Xd+uPvM4wadd8HCz5w2t+ugHh8mu0OBMvK/PjSQQxLozRxdcZEOy+wqnk5OrCYSfpx18gJa/RjgGe2EkgPRlvLRfi2dr47eCUrYUs7RZfod7XRjhauFaeG4dEgCApojGLJ6WNi0IwwzbjTQ7fzAJMalnF4f7alb1OrW28opZmhFmCF0= zach5@Glacier"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILepe2FGl5nzpyRWcHkRO8CPDygovL80Qik+HV8ypBAN zman@warframe"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEEzlQKun0aGnDcpkDzczg1EGoxWqaVgFUW0umooAi9x glacier@wsl"
        ];
        initialHashedPassword = "$y$j9T$RbcN4mdZop6gD9K4x07AH/$XKRWxzJnp8gJM3UF/W8p8DwvC4EADEAsvxFU0KDCbw7";
      };
    };
  };

  # System configuration
  system.stateVersion = "24.11";
}
