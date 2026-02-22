{ config, pkgs, ... }:

{
  # User management
  users = {
    mutableUsers = false;
    
    users.zman = {
      isNormalUser = true;
      description = "zman user";
      extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" ];
      
      # SSH keys can be added here or managed separately
      openssh.authorizedKeys.keys = [
        # Add your SSH public key here
        # "ssh-rsa AAAAB3... user@host"
      ];
      
      # Initial password (should be changed on first login)
      initialHashedPassword = "$y$j9T$RbcN4mdZop6gD9K4x07AH/$XKRWxzJnp8gJM3UF/W8p8DwvC4EADEAsvxFU0KDCbw7";
    };
  };

  # Sudo access for wheel group
  security.sudo.wheelEnabled = true;
  security.sudo.wheelNeedsPassword = false;
}