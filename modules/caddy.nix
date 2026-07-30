{ pkgs, config, lib, ... }:

let
  caddySecrets = import ../secrets/caddy.nix;

  # Path where ACME stores the certs (read by Caddy)
  certPath = "/var/lib/acme/zachru.com";

  # TLS config re-used by all zachru.com vhosts — points to ACME-managed certs
  zachruTls = ''
    tls ${certPath}/cert.pem ${certPath}/key.pem {
      protocols tls1.3
    }
  '';
in

{
  ### Certificates — provisioned by security.acme, NOT by Caddy ###
  # ACME uses lego under the hood, which has official GoDaddy DNS support.
  # A wildcard cert covers all *.zachru.com subdomains.
  # ACME's systemd timer auto-renews; postRun reloads Caddy after renewal.
  security.acme = {
    enable = true;
    acceptTerms = true;
    defaults.email = "zach@zachru.com";

    certs."zachru.com" = {
      # Wildcard cert — covers zachru.com AND *.zachru.com
      extraDomainNames = [ "*.zachru.com" ];

      dnsProvider = "godaddy";
      environmentFile = pkgs.writeText "godaddy-creds" ''
        GODADDY_API_KEY=${caddySecrets.godaddyApiToken}
        GODADDY_API_SECRET=${caddySecrets.godaddyApiSecret}
      '';

      # Let Caddy read the cert files
      group = config.services.caddy.group;

      # Reload Caddy after cert renewal so it picks up the new certs
      postRun = ''
        systemctl reload caddy || true
      '';
    };
  };

  ### Caddy — reverse proxy only, no cert management ###
  networking.firewall.allowedTCPPorts = [ 443 ];

  services.caddy = {
    enable = true;
    # Stock Caddy package — no custom plugins needed

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

      # --- Tailscale internal hosts (self-signed, existing access method) ---

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
