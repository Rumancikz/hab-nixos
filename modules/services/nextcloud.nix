{ self, config, lib, pkgs, ... }:

let
  # Check if sops-nix secrets are available
  sopsEnabled = config.homelab.secrets.enable or false;
in
{
    # Sops-nix secret configuration for Nextcloud
    sops.secrets."nextcloud/admin-password" = lib.mkIf sopsEnabled {
      owner = config.services.nextcloud.user;
      group = config.services.nextcloud.group;
      mode = "0400";
      sopsFile = ./../secrets/nextcloud.yaml;
      key = "nextcloud/admin-password";
    };

    services = {

    #   "onlyoffice.hab.com" = {
    #     forceSSL = true;
    #     # enableACME = true;
    #   };
    # };

    nextcloud = {
      enable = true;
      hostName = "0.0.0.0";
      datadir = "/tank/nextcloud";
       # Need to manually increment with every major upgrade.
      package = pkgs.nextcloud30;

      # Let NixOS install and configure the database automatically.
      database.createLocally = true;

      # Let NixOS install and configure Redis caching automatically.
      configureRedis = true;

      # Increase the maximum file upload size to avoid problems uploading videos.
      maxUploadSize = "16G";
      # https = true;
      # enableBrokenCiphersForSSE = false;

      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; {
        # List of apps we want to install and are already packaged in
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
        inherit calendar contacts mail notes onlyoffice tasks memories;

        # # Custom app installation example.
        # cookbook = pkgs.fetchNextcloudApp rec {
        #   url =
        #     "https://github.com/nextcloud/cookbook/releases/download/v0.9.19/Cookbook-0.9.19.tar.gz";
        #   sha256 = "sha256-XgBwUr26qW6wvqhrnhhhhcN4wkI+eXDHnNSm1HDbP6M=";
        # };
      };
      settings = {
        # overwriteprotocol = "http";
        # overwritehost = "127.0.0.1";
        # overwritewebroot = "/nextcloud";
        # overwrite.cli.url = "http://127.0.0.1/nextcloud/";
        # htaccess.RewriteBase = "/nextcloud";
        trusted_domains = [
          "10.0.0.6"
        ];
      };

      config = {
        # overwriteProtocol = "https";
        # defaultPhoneRegion = "PT";
        dbtype = "pgsql";
        # dbtype = "sqlite";
        adminuser = "admin";
        # Use sops-nix secret if available, otherwise fallback to /etc/nextcloudadminpass
        adminpassFile = if sopsEnabled 
          then config.sops.secrets."nextcloud/admin-password".path 
          else "/etc/nextcloudadminpass";
      };
    };

    # onlyoffice = {
    #   enable = true;
    #   hostname = "0.0.0.0";
    # };


    #  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = lib.mkIf nc-config.enableHttps {
    #   forceSSL = true;
    #   enableACME = true;
    # };

  };

}
