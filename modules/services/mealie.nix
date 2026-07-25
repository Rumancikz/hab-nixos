{ self, config, lib, pkgs, ... }:

{
 
  services.mealie = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9000;

    settings = {
      # DB_ENGINE = "postgres";
      OPENAI_API_BASE = "http://habai:8080/v1";
      OPENAI_API_KEY = "habai";
      SUB_PATH = "/mealie";
    };
  };

}