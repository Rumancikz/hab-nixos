{ self, config, lib, pkgs, ... }:

let
  # Check if sops-nix secrets are available
  sopsEnabled = config.homelab.secrets.enable or false;
in
{
  # Sops-nix secret configuration for Firefly-III
  sops.secrets."firefly/app-key" = lib.mkIf sopsEnabled {
    owner = config.services.firefly-iii.user or "firefly-iii";
    group = config.services.firefly-iii.group or "firefly-iii";
    mode = "0400";
    sopsFile = ./../secrets/firefly.yaml;
    key = "firefly/app-key";
  };

  sops.secrets."firefly/db-password" = lib.mkIf sopsEnabled {
    owner = config.services.firefly-iii.user or "firefly-iii";
    group = config.services.firefly-iii.group or "firefly-iii";
    mode = "0400";
    sopsFile = ./../secrets/firefly.yaml;
    key = "firefly/db-password";
  };

  # environment.etc."fireflyappkey".text = "PvgdXZVTo3ZEM9eDU4hGa5LIrQfXmKZh";
  # environment.etc."fireflydbpassword".text = "testpassword";

  # services.firefly-iii = {

  #   enable = true;
  #   dataDir = "/tank/firefly-iii/";
  #   settings = {
  #     APP_ENV = "production";
  #     APP_KEY_FILE = if sopsEnabled 
  #       then config.sops.secrets."firefly/app-key".path 
  #       else "/etc/fireflyappkey";
  #     SITE_OWNER = "test@test.com";
  #     DB_CONNECTION = "mysql";
  #     DB_HOST = "db";
  #     DB_PORT = 3306;
  #     DB_DATABASE = "firefly";
  #     DB_USERNAME = "firefly";
  #     DB_PASSWORD_FILE = if sopsEnabled 
  #       then config.sops.secrets."firefly/db-password".path 
  #       else "/etc/fireflydbpassword";
  #     TZ = "America/New_York";
  #   };

  #   enableNginx = false;
  #   virtualHost = "localhost";

  # };

}