{ config, pkgs, ... }:

{
  
  environment.systemPackages = with pkgs; [
    paperless-ngx
  ];

}