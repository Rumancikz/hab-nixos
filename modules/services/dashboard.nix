{ self, config, lib, pkgs, ... }:

{

services.homepage-dashboard = {
  enable = true;
  # Default port is 8082
  listenPort = 8082;

  allowedHosts = "10.0.0.6:8082,localhost:8082";

  services = [
    {
      "Core Services" = [
        {
          "Nextcloud" = {
            icon = "nextcloud.png";
            href = "http://10.0.0.6:8008";
            description = "File Cloud & Collaboration";
          };
        }
      ];
    }
    {
      "Home Management" = [
        {
          "Mealie" = {
            icon = "mealie.png";
            href = "http://10.0.0.6:9000";
            description = "Recipe Manager & Meal Planner";
            # widget = {
            #   type = "mealie";
            #   url = "http://10.0.0.6:9000";
            #   # version 2 is standard for modern Mealie
            #   version = 2; 
            #   # Get this in Mealie: Profile > Manage API Tokens
            #   key = "your-mealie-api-key"; 
            # };
          };
        }
        {
          "Paperless" = {
            icon = "paperless-ngx.png";
            href = "http://10.0.0.6:3343";
            description = "Document Archiving";
          };
        }
      ];
    }
  ];

  # Global settings for the dashboard
  settings = {
    title = "My NixOS Homelab";
    headerStyle = "clean";
    layout = {
      "Core Services" = {
        columns = 1;
      };
      "Home Management" = {
        columns = 2;
      };
    };
  };
};

# Open the firewall for the dashboard
networking.firewall.allowedTCPPorts = [ 8082 ];

}