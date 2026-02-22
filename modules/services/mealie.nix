{ self, config, lib, pkgs, ... }:

{
 
  services.mealie = {

    enable = true;
    listenAddress = "0.0.0.0";
    port = 9000;
    settings = {
      # DB_ENGINE = "postgres";
    };

  };

}