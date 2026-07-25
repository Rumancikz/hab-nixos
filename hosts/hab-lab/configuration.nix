# Main configuration for hab-lab-1 home lab server
# Build commands:
#   Local build:  nixos-rebuild switch --flake .#hab-lab
#   Remote build: nixos-rebuild switch --flake .#hab-lab --target-host hab-lab@10.0.0.6 --use-remote-sudo
{ config, lib, pkgs, modulesPath, inputs, ... }:

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
        443   # Caddy HTTPS (dashboard)
        7443  # Caddy HTTPS (paperless)
        8443  # Caddy HTTPS (mealie)
        9443  # Caddy HTTPS (webui)
        # config.services.firefly-iii.settings.DB_PORT
        config.services.mealie.port
      ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Override mealie to pin to v3.21.0 (nixpkgs has 3.16.0)
  # Source comes from flake input `inputs.mealie` (see flake.nix).
  # The nixpkgs mealie derivation builds the frontend separately
  # (mealie-frontend.nix) so we need a standalone derivation.
  nixpkgs.overlays = [
    (final: prev: {
      mealie = let
        src = inputs.mealie.outPath;
        # Build the Nuxt frontend (yarn generate produces a static SPA)
        mealieFrontend = prev.stdenv.mkDerivation rec {
          pname = "mealie-frontend";
          version = "3.21.0";
          src = src + "/frontend";
          nativeBuildInputs = [ prev.nodejs prev.yarn ];
          installPhase = ''
            yarn install --frozen-lockfile --non-interactive --production=false
            yarn generate
            mkdir -p $out
            cp -r dist/* $out/
          '';
        };
        # Build the Python package with the frontend bundled in
        mealiePkg = prev.python3Packages.buildPythonApplication rec {
          pname = "mealie";
          version = "3.21.0";
          src = src;
          format = "pyproject";
          preBuild = ''
            rm -rf mealie/frontend
            cp -r ${mealieFrontend} mealie/frontend
          '';
          postPatch = ''
            substituteInPlace pyproject.toml --replace "setuptools==83.0.0" "setuptools>=80.0.0" || true
            substituteInPlace pyproject.toml --replace ">=3.12,<3.13" ">=3.12" || true
            substituteInPlace mealie/__init__.py --replace '"develop"' '"3.21.0"'
          '';
        };
      in mealiePkg;
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

  # Caddy reverse proxy — handles HTTPS for services
  # Uses Caddy's internal CA (tls internal) since tailnet domains aren't publicly resolvable
  services.caddy = {
    enable = true;
    virtualHosts = {
      # Mealie on port 8443
      "hab-lab-1:8443" = {
        extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:9000
        '';
      };
      # Open WebUI on port 9443
      "hab-lab-1:9443" = {
        extraConfig = ''
          tls internal
          reverse_proxy habai:3000
        '';
      };
      # Dashboard on default HTTPS (no port)
      "hab-lab-1" = {
        extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:8082
        '';
      };
      # Paperless on port 7443
      "hab-lab-1:7443" = {
        extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:3343
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