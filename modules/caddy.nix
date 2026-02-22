{ pkgs, config, ... }:
{

  # networking.firewall.allowedTCPPorts = [ 80 443 ];

  # services.caddy = {
  #   enable = true;
  #   virtualHosts."hab.lab.test.website.dev".extraConfig = ''
  #     reverse_proxy http://localhost:9000
  #   '';
  # };

}