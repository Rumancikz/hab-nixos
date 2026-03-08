{ config, pkgs, ... }:

{
  home.username = "zman";
  home.homeDirectory = "/home/zman";
  
  home.stateVersion = "24.11"; 

  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "you@example.com";
  };
}