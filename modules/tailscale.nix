{ config, pkgs, ... }:

{
  
  # make the tailscale command usable to users
  environment.systemPackages = [ pkgs.tailscale pkgs.jq ];

  # enable the tailscale service
  services.tailscale.enable = true;

}