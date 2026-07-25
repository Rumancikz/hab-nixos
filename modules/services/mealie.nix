{ self, config, lib, pkgs, ... }:

{
 
  services.mealie = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9000;

    # OpenAI-compatible AI provider (local habai endpoint)
    environment = {
      OPENAI_API_BASE = "http://habai:8080/v1";
      OPENAI_API_KEY = "habai";  # adjust if your endpoint requires a real key
    };

    settings = {
      # DB_ENGINE = "postgres";
    };
  };

}