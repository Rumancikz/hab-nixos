{ config, lib, ... }:
let
  service = "paperless";
  cfg = config.homelab.services.${service};
  homelab = config.homelab;
  # Check if sops-nix secrets are available
  sopsEnabled = config.homelab.secrets.enable or false;
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "/tank/Paperless/Documents";
    };
    consumptionDir = lib.mkOption {
      type = lib.types.str;
      default = "/tank/Paperless/Import";
    };
    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = if sopsEnabled then config.sops.secrets."paperless/password".path else null;
      description = "Path to the file containing the Paperless admin password";
    };
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/${service}";
    };
    # url = lib.mkOption {
    #   type = lib.types.str;
    #   default = "paperless.${homelab.baseDomain}";
    # };
    monitoredServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "paperless-consumer"
        "paperless-scheduler"
        "paperless-task-queue"
        "paperless-web"
      ];
    };
    homepage.name = lib.mkOption {
      type = lib.types.str;
      default = "Paperless-ngx";
    };
    homepage.description = lib.mkOption {
      type = lib.types.str;
      default = "Document management system";
    };
    homepage.icon = lib.mkOption {
      type = lib.types.str;
      default = "paperless.svg";
    };
    homepage.category = lib.mkOption {
      type = lib.types.str;
      default = "Services";
    };

  };
  config = lib.mkIf cfg.enable {
    # Sops-nix secret configuration for Paperless
    sops.secrets."paperless/password" = lib.mkIf sopsEnabled {
      owner = cfg.user;
      group = "paperless";
      mode = "0400";
      sopsFile = ./../secrets/paperless.yaml;
      key = "paperless/password";
    };

    services = {
      ${service} = {
        enable = true;
        passwordFile = cfg.passwordFile;
        user = "hab-lab";
        port = 3343;
        address = "0.0.0.0";
        mediaDir = cfg.mediaDir;
        consumptionDir = cfg.consumptionDir;
        consumptionDirIsPublic = true;
        settings = {
          PAPERLESS_PORT = 3343;
          PAPERLESS_URL = "http://127.0.0.1:3343";
          PAPERLESS_CONSUMER_IGNORE_PATTERN = [
            ".DS_STORE/*"
            "desktop.ini"
          ];
          PAPERLESS_OCR_LANGUAGE = "eng";
          PAPERLESS_CONSUMER_RECURSIVE = true;
          PAPERLESS_OCR_USER_ARGS = {
            optimize = 1;
            pdfa_image_compression = "lossless";
          };
        };
      };
      # caddy.virtualHosts."${cfg.url}" = {
      #   useACMEHost = homelab.baseDomain;
      #   extraConfig = ''
      #     reverse_proxy http://127.0.0.1:3343
      #   '';
      # };
    };
  };
}
