{ config, pkgs, ... }:

{
  # User management
  users = {
    mutableUsers = true;
    
    users.zman = {
      isNormalUser = true;
      description = "Zman Da Man";
      extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
      
      packages = with pkgs; [
        alacritty
        keepassxc
        syncthing
        google-chrome
        htop
        libreoffice
        vlc
        ffmpeg
        obs-studio
        vscodium
      ];

      # SSH keys can be added here or managed separately
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEEzlQKun0aGnDcpkDzczg1EGoxWqaVgFUW0umooAi9x glacier@wsl"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmQPAF7mkBlbA8Ldbw0xd+sjva0mwKUTwwp6MNJpAw3 habphrite@phone"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAB75ux2lawn72cpqBP7feWjpkSs7CgxW6Gq1VIdYPih termux@zab"
      ];
      
      # Initial password (should be changed on first login)
      initialHashedPassword = "$y$j9T$RbcN4mdZop6gD9K4x07AH/$XKRWxzJnp8gJM3UF/W8p8DwvC4EADEAsvxFU0KDCbw7";
    };
  };

}