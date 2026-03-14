{ self, config, lib, pkgs, ... }:

{

services.homepage-dashboard = {
  enable = true;
  # Default port is 8082
  listenPort = 8082;
  environment = {
    HOMEPAGE_ALLOWED_HOSTS = "10.0.0.6:8082,0.0.0.0:8082";
  };
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
    background = {
      image = "https://images.unsplash.com/photo-1518770660439-4636190af475"; # Or a local path
      opacity = 50;
    };
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