{ pkgs, config, lib, ... }:

let
  # ⚠️ Replace these with real values on the target host (keep repo dirty)
  # Get them from: https://developer.godaddy.com/keys/
  # Quick API check (200 = OK, 403 = GoDaddy API restricted for this account):
  #   curl -s -o /dev/null -w '%{http_code}' \
  #     -H "Authorization: sso-key ${KEY}:${SECRET}" \
  #     https://api.godaddy.com/v1/domains/zachru.com
  godaddyApiKey  = "";
  godaddyApiSecret = "";

  # ACME stores certs here: fullchain.pem + key.pem
  certDir = "/var/lib/acme/zachru.com";

  # TLS config re-used by all zachru.com vhosts
  zachruTls = ''
    tls ${certDir}/fullchain.pem ${certDir}/key.pem
  '';
in

{
  ### Certificates — provisioned by security.acme (lego) ###
  security.acme = {
    acceptTerms = true;
    defaults.email = "zach@zachru.com";

    certs."zachru.com" = {
      
      domain = "zachru.com";
      extraDomainNames = [ "*.zachru.com" ];

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

    # Don't let Caddy try ACME — security.acme (lego) provisions certs into
    # ${certDir} and we load them with explicit `tls` directives above.
    # If the cert files are missing, Caddy falls back to its internal CA
    # (self-signed — the warnings you've been seeing).
    globalConfig = ''
      auto_https disable_certs
    '';

    virtualHosts = {
      # --- zachru.com domains (Let's Encrypt via security.acme/lego, DNS-01 through GoDaddy) ---
      # One cert covers apex + wildcard: domain = "zachru.com" with
      # extraDomainNames = [ "*.zachru.com" ] → SAN: zachru.com, *.zachru.com.
      # Every A record points at 100.104.22.20 (RFC 6598 CGNAT) — reachable only
      # from inside the tailnet, so the domain is Tailscale-only by construction.

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
          reverse_proxy 127.0.0.1:${toString config.services.mealie.port}
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
      "git.zachru.com" = {
        extraConfig = ''
          ${zachruTls}
          reverse_proxy 127.0.0.1:3000
        '';
      };
      # NOTE: the old hab-lab-1:8443/9443/7443 + hab-lab-1 vhosts are removed —
      # they only ever served Caddy's internal CA (per-device warnings).
      # Use the domain URLs instead; they resolve to the same Tailscale IP.
    };
  };
}
