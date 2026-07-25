{ self, config, lib, pkgs, ... }:

{

    environment.etc."nextcloudadminpass".text = "testpassword";

  networking.firewall.allowedTCPPorts = [ 80 ];

  services = {

    nginx = {
      enable = true;
      virtualHosts."100.104.22.20" = {
        listen = [ { addr = "100.104.22.20"; port = 8008; } ];
      };
      virtualHosts."10.0.0.6" = {
        listen = [ { addr = "10.0.0.6"; port = 8008; } ];
      };
    };

    nextcloud = {
      enable = true;
      hostName = "100.104.22.20";
      datadir = "/tank/nextcloud";
       # Need to manually increment with every major upgrade.
      package = pkgs.nextcloud33;

      # Database and Caching
      database.createLocally = true;
      configureRedis = true;
      maxUploadSize = "100G";

      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; {
        # List of apps we want to install and are already packaged in
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
        inherit 
          calendar 
        #   contacts 
        #   mail 
        #   notes 
          onlyoffice 
        #   tasks 
        #   memories
        ;

        # # Custom app installation example.
        # cookbook = pkgs.fetchNextcloudApp rec {
        #   url =
        #     "https://github.com/nextcloud/cookbook/releases/download/v0.9.19/Cookbook-0.9.19.tar.gz";
        #   sha256 = "sha256-XgBwUr26qW6wvqhrnhhhhcN4wkI+eXDHnNSm1HDbP6M=";
        # };
      };
      settings = {
        trusted_domains = [ "100.104.22.20" "10.0.0.6" ];
        overwritehost = "100.104.22.20:8008";
        overwriteprotocol = "http";
      };

      config = {
        dbtype = "pgsql";
        adminuser = "admin";
        adminpassFile = "/etc/nextcloudadminpass";
      };
    };
  };
}