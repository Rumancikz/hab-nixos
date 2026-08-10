{ self, config, lib, pkgs, ... }:

{

services.homepage-dashboard = {
  enable = true;
  # Default port is 8082
  listenPort = 8082;

  allowedHosts = "localhost:8082,100.104.22.20:8082,10.0.0.6:8082,hab-lab-1,hab-lab-1:443,zachru.com,zachru.com:443,hab-lab-1.zachru.com,hab-lab-1.zachru.com:443";

  services = [
    {
      "Core Services" = [
        {
          "Nextcloud" = {
            icon = "nextcloud.png";
            href = "http://100.104.22.20:8008";
            description = "File Cloud & Collaboration";
          };
        }
                {
          "OpenWebUI" = {
            icon = "openwebui.png";
            href = "https://ai.zachru.com";
            description = "Private Local LLM";
          };
        }
      ];
    }
    {
      "Home Management" = [
        {
          "Mealie" = {
            icon = "mealie.png";
            href = "https://mealie.zachru.com";
            description = "Recipe Manager & Meal Planner";
          };
        }
        {
          "Paperless" = {
            icon = "paperless-ngx.png";
            href = "https://paperless.zachru.com";
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