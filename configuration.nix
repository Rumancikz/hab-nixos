{
  modulesPath,
  lib,
  pkgs,
  config,
  ...
}:

{
  # ==========================================
  # System Imports
  # ==========================================
  imports = [
    ./disk-config.nix
    ./nixosModules
  ];

  # 10.0.0.1 - Current network router
  # 10.0.0.2 - hab-atlas
  # 10.0.0.4 - pikvm 1
  # 10.0.0.65 - Hab Lab 1

  #To use nixos-anywhere to deploy to a remote computer, use the following snippet.
  #nix run github:nix-community/nixos-anywhere -- --disko-mode disko --flake ~/Documents/nixos-anywhere/nixos#hab --generate-hardware-config nixos-generate-config ./hardware-configuration.nix root@10.0.0.6
  
  #Afterwards, copy the files to the remote machine
  # cd ~/Documents/nixos-anywhere/nixos
  # scp -r ./ root@10.0.0.6:/etc/nixos
  # mkdir /etc/nixos/ssh
  # mkdir /etc/nixos/ssh/authorized_keys
  # scp -r ./secrets/ root@10.0.0.66:/etc/nixos/ssh/authorized_keys/

  #rebuild without overwriting everything
  #nixos-rebuild switch --flake .#generic --target-host root@10.0.0.65
  
  # zpool import ocean -d /dev -o readonly=on -f -R /ocean
  # zfs get mountpoint ocean/tank
  # mount -t zfs ocean/tank /ocean
  # zpool export ocean

  # ==========================================
  # Boot Configuration
  # ==========================================
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  boot.supportedFilesystems = ["zfs" "btrfs"];

  # ==========================================
  # Nix Settings
  # ==========================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ==========================================
  # Networking
  # ==========================================
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

  # ==========================================
  # Nixpkgs Configuration
  # ==========================================
  nixpkgs.config.allowUnfree = true;

  # ==========================================
  # Services
  # ==========================================
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  services.fail2ban.enable = true;

  # ==========================================
  # Environment
  # ==========================================
  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  # ==========================================
  # Localization
  # ==========================================
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # ==========================================
  # Users
  # ==========================================
  users = {
    mutableUsers = false;
#SSH Keys are probably not right anymore. Set up nix-sops to store them in less
    users = {
      root = {
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGobqsOAomSQvVfN/I0TQlqTMcD/W4h3W6/9taeLeC4Sx4XtcPZRNfrfeNeBfgCsEt4VZtjFOnZPAbqPOOpmQC44K5a9OBxDakhiWLdJlOMFlBxtW25TOny62ow7/qPVTsTInfT7RgGJ5zg/zIm0/92DEZJ4zihJSk3QbToX+vo+llWb9OaJMFiKdXgMGGOfufvX17bKWFop5CVgTKczw+GbNKzvne4oPXjw7WOF8egeJBnqQdDKj9qy/6Emoc9lLeK/TBsxEy71TkIT5xhBOlf1l9gZo+laBE5KK/3rSbPyTMMev0nejsxO4PtL757uzcgW21VGV2ZVFXgLx3Xd+PvM4wadd8HCz5w2t+ugHh8mu0OBMvK/PjSQQxLozRxdcZEOy+wqnk5OrCYSfpx18gJa/RjgGe2EkgPRlvLRfi2dr47eCUrYUs7RZfod7XRjhauFaeG4dEgCApojGLJ6WNi0IwwzbjTQ7fzAJMalnF4f7al1OrW28opZmhFmCF0= zach5@Glacier"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILepe2FGl5nzpyRWcHkRO8CPDygovL80Qik+HV8ypBAN zman@warframe"
        ];
        initialHashedPassword = "$y$j9T$RbcN4mdZop6gD9K4x07AH/$XKRWxzJnp8gJM3UF/W8p8DwvC4EADEAsvxFU0KDCbw7";
      };

      hab-lab = {
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGobqsOAomSQvVfN/I0TQlqTMcD/W4h3W6/9taeLeC4Sx4XtcPZRNfrfeNeBfgCsEt4VZtjFOnZPAbqPOOpmQC44K5a9OBxDakhiWLdJlOMFlBxtW25TOny62ow7/qPVTsTInfT7RgGJ5zg/zIm0/92DEZJ4zihJSk3QbToX+vo+llWb9OaJMFiKdXgMGGOfufvX17bKWFop5CVgTKczw+GbNKzvne4oPXjw7WOF8egeJBnqQdDKj9qy/6Emoc9lLeK/TBsxEy71TkIT5xhBOlf1l9gZo+laBE5KK/3rSbPyTMMev0nejsxO4PtL757uzcgW21VGV2ZVFXgLx3Xd+PvM4wadd8HCz5w2t+ugHh8mu0OBMvK/PjSQQxLozRxdcZEOy+wqnk5OrCYSfpx18gJa/RjgGe2EkgPRlvLRfi2dr47eCUrYUs7RZfod7XRjhauFaeG4dEgCApojGLJ6WNi0IwwzbjTQ7fzAJMalnF4f7al1OrW28opZmhFmCF0= zach5@Glacier"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILepe2FGl5nzpyRWcHkRO8CPDygovL80Qik+HV8ypBAN zman@warframe"
        ];
        initialHashedPassword = "$y$j9T$RbcN4mdZop6gD9K4x07AH/$XKRWxzJnp8gJM3UF/W8p8DwvC4EADEAsvxFU0KDCbw7";
        isNormalUser = true;
        extraGroups = [ "video" "render" "wheel" ];
      };
    };
  };

  # ==========================================
  # Reverse Proxies
  # ==========================================
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    virtualHosts = {
      "${config.services.nextcloud.hostName}" = {
        forceSSL = false;
        listen = [
          { addr = "10.0.0.65"; port = 8080; }
        ];
      };
      "${config.services.firefly-iii.virtualHost}" = {
        forceSSL = false;
        listen = [
          { addr = "10.0.0.65"; port = 3306; }
        ];
      };
      "immich" = {
        forceSSL = false;
        listen = [
          { addr = "10.0.0.65"; port = 2283; }
        ];
      };
    };
  };

  # ==========================================
  # System Version
  # ==========================================
  system.stateVersion = "24.05";
}
