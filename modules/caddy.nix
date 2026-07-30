{ pkgs, config, lib, ... }:

let
  # ⚠️ Replace these with real values on the target host (keep repo dirty)
  # Get them from: https://developer.godaddy.com/keys/
  godaddyApiKey  = "";
  godaddyApiSecret = "";

  # ACME stores certs here: fullchain.pem + key.pem
  certDir = "/var/lib/acme/zachru.com";

  # TLS config re-used by all zachru.com vhosts
  zachruTls = ''
    tls ${certDir}/fullchain.pem ${certDir}/key.pem {
      protocols tls1.3
    }
  '';
in

{
  ### Certificates — provisioned by security.acme (lego) ###
  security.acme = {
    acceptTerms = true;
    defaults.email = "zach@zachru.com";

    certs."zachru.com" = {
      # Wildcard cert covers *.zachru.com (base domain is included automatically)
      domain = "*.zachru.com";

      dnsProvider = "godaddy";
      environmentFile = pkgs.writeText "godaddy-creds" ''
        GODADDY_API_KEY=${godaddyApiKey}
        GODADDY_API_SECRET=${godaddyApiSecret}
      '';

      # Let Caddy read the cert files
      group = config.services.caddy.group;

      # Reload Caddy after cert renewal
      reloadServices = [ "caddy" ];
    };
  };

  ### Caddy — reverse proxy only ###
  networking.firewall.allowedTCPPorts = [ 443 ];

  services.caddy = {
    enable = true;

    virtualHosts = {
      # --- zachru.com domains (Let's Encrypt certs via ACME) ---

      "zachru.com" = {
        extraConfig = ''
          ${zachruTls}
          reverse_proxy 127.0.0.1:8082
        '';
      };

      "hab-lab-1.zachru.com" = {
        extraConfig = ''
          ${zachruTls}
          reverse_proxy 127.0.0.1:8082
        '';
      };

      "mealie.zachru.com" = {
        extraConfig = ''
          ${zachruTls}
          reverse_proxy 127.0.0.1:9000
        '';
      };

      "ai.zachru.com" = {
        extraConfig = ''
          ${zachruTls}
          reverse_proxy habai:3000
        '';
      };

      "paperless.zachru.com" = {
        extraConfig = ''
          ${zachruTls}
          reverse_proxy 127.0.0.1:3343
        '';
      };

      # --- Tailscale internal hosts (self-signed) ---

      "hab-lab-1:8443" = {
        extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:9000
        '';
      };

      "hab-lab-1:9443" = {
        extraConfig = ''
          tls internal
          reverse_proxy habai:3000
        '';
      };

      "hab-lab-1" = {
        extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:8082
        '';
      };

      "hab-lab-1:7443" = {
        extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:3343
        '';
      };
    };
  };
}
