{ self, config, lib, pkgs, ... }:

{

    environment.etc."nextcloudadminpass".text = "testpassword";

  networking.firewall.allowedTCPPorts = [ 80 ];

  services = {

    nginx = {
      enable = true;
      virtualHosts."127.0.0.1" = {
        listen = [ { addr = "127.0.0.1"; port = 8080; } ];
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
        trusted_domains = [ "100.104.22.20" "10.0.0.6" "hab-lab-1" ];
        overwritehost = "hab-lab-1:8008";
        overwriteprotocol = "https";
      };

      config = {
        dbtype = "pgsql";
        adminuser = "admin";
        adminpassFile = "/etc/nextcloudadminpass";
      };
    };
  };
}