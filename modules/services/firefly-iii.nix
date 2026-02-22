{ self, config, lib, pkgs, ... }:
{

  environment.etc."fireflyappkey".text = "PvgdXZVTo3ZEM9eDU4hGa5LIrQfXmKZh";
  environment.etc."fireflydbpassword".text = "testpassword";

  services.firefly-iii = {

    enable = true;
    dataDir = "/tank/firefly-iii/";
    settings = {
      APP_ENV = "production";
      APP_KEY_FILE = "/etc/fireflyappkey";
      SITE_OWNER = "test@test.com";
      DB_CONNECTION = "mysql";
      DB_HOST = "db";
      DB_PORT = 3306;
      DB_DATABASE = "firefly";
      DB_USERNAME = "firefly";
      DB_PASSWORD_FILE = "/etc/fireflydbpassword";
      TZ = "America/New_York";
    };

    enableNginx = true;
    virtualHost = "localhost";

  };

}