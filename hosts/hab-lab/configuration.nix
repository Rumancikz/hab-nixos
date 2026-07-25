# Main configuration for hab-lab-1 home lab server
# Build commands:
#   Local build:  nixos-rebuild switch --flake .#hab-lab
#   Remote build: nixos-rebuild switch --flake .#hab-lab --target-host hab-lab@10.0.0.6 --use-remote-sudo
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ../../disk-config.nix
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

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [
    "zman"
    "hab-lab"
  ];

    networking = {
    hostId = "007f0201";
    hostName = "hab-lab-1";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        8080
        8008
        3343
        443  # Caddy HTTPS
        # config.services.firefly-iii.settings.DB_PORT
        config.services.mealie.port
      ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Override mealie to pin to a specific upstream commit (nixpkgs version is outdated)
  nixpkgs.overlays = [
    (final: prev: {
      mealie = prev.mealie.overrideAttrs (old: {
        src = prev.fetchFromGitHub {
          owner = "mealie-recipes";
          repo  = "mealie";
          rev   = "e22b8e7b734fb56d6f54a44526005104d3ac8f30"; # v3.21.0
          sha256 = "sha256-z1FQx5tngM/H78uLcaKENPFl7bWamIC0hPs1r8xM9PA=";
        };
        version = "3.21.0";
        # v3.21.0 pins setuptools==83.0.0 but nixpkgs provides a different version.
        # Relax the pin so the build accepts nixpkgs' setuptools.
        postPatch = ''
          substituteInPlace pyproject.toml --replace "setuptools==83.0.0" "setuptools>=80.0.0" || true
        '';
      });
    })
  ];

  # Services
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    ports = [ 22 ];
  };

  homelab.services.paperless = {
    enable = true;
  };

  services.fail2ban.enable = true;

  # Caddy reverse proxy — handles HTTPS and routes to services
  services.caddy = {
    enable = true;
    virtualHosts = {
      "mealie.hab-lab-1" = {
        extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:9000
        '';
      };
      "webui.hab-lab-1" = {
        extraConfig = ''
          tls internal
          reverse_proxy habai:3000
        '';
      };
    };
  };

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
        initialHashedPassword = "$y$j9T$cNbdmEM4c64BgP4m/Smhh0$BoDpBSkFcX6uhoqljSUQ73GDOnpfrNpsi0G1ySGc48B";
      };
      hab-lab = {
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGobqsOAomSQvVfN/I0TQlqTMcD/W4h3W6/9taeLeC4Sx4XtcPZRNfrfeNeBfgCsEt4VZtjFOnZPAbqPOOpmQC44K5a9OBxDakhiWLdJlOMFlBxtW25TOny62ow7/qPVTsTInfT7RgGJ5zg/zIm0/92DEZJ4zihJSk3QbToX+vo+llWb9OaJMFiKdXgMGGOfufvX17bKWFop5CVgTKczw+GbNKzvne4oPXjw7WOF8egeJBnqQdDKj9qy/6Emoc9lLeK/TBsxEy71TkIT5xhBOlf1l9gZo+laBE5KK/3rSbPyTMMev0nejsxO4PtL757uzcgW21VGV2ZVFXgLx3Xd+uPvM4wadd8HCz5w2t+ugHh8mu0OBMvK/PjSQQxLozRxdcZEOy+wqnk5OrCYSfpx18gJa/RjgGe2EkgPRlvLRfi2dr47eCUrYUs7RZfod7XRjhauFaeG4dEgCApojGLJ6WNi0IwwzbjTQ7fzAJMalnF4f7alb1OrW28opZmhFmCF0= zach5@Glacier"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILepe2FGl5nzpyRWcHkRO8CPDygovL80Qik+HV8ypBAN zman@warframe"
        ];
        initialHashedPassword = "$y$j9T$cNbdmEM4c64BgP4m/Smhh0$BoDpBSkFcX6uhoqljSUQ73GDOnpfrNpsi0G1ySGc48B";
        isNormalUser = true;
        extraGroups = [ "video" "render" "wheel" ];
      };
    };
  };

  # System configuration
  system.stateVersion = "24.05";
}