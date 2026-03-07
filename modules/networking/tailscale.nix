{ config, pkgs, ... }:

{
  
  # make the tailscale command usable to users
  environment.systemPackages = with pkgs; [ 
    tailscale 
    jq 
  ];

  # enable the tailscale service
  services.tailscale.enable = true;

}