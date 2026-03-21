# Secrets Management with Sops-nix

This document explains how to use sops-nix for secure secrets management in your NixOS configuration.

## Overview

Sops-nix encrypts secrets at rest using age encryption and decrypts them at system activation time. This keeps secrets out of the Nix store and version control history while making them available to services that need them.

## Architecture

```
secrets/*.yaml (encrypted) → sops-nix → /run/secrets/* (decrypted at activation)
```

- **Encrypted files** are stored in `secrets/*.yaml`
- **Decrypted secrets** appear in `/run/secrets/` at boot/activation
- **Age key** is stored at `/var/lib/sops-nix/key.txt` on each host

## Initial Setup

### 1. Generate an Age Key

On your development machine:

```bash
# Generate a new age key
nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"

# View your public key
nix-shell -p age --run "age-keygen -y ~/.config/sops/age/keys.txt"
```

### 2. Update .sops.yaml

Edit `.sops.yaml` and replace the placeholder with your actual public key:

```yaml
keys:
  - &shared-key age1YOUR_ACTUAL_PUBLIC_KEY_HERE
```

### 3. Create Encrypted Secret Files

Copy the example files and edit them:

```bash
# Copy example files
cp secrets/users.example.yaml secrets/users.yaml
cp secrets/nextcloud.example.yaml secrets/nextcloud.yaml
cp secrets/paperless.example.yaml secrets/paperless.yaml
cp secrets/firefly.example.yaml secrets/firefly.yaml

# Edit and encrypt each file
nix-shell -p sops --run "sops secrets/users.yaml"
nix-shell -p sops --run "sops secrets/nextcloud.yaml"
nix-shell -p sops --run "sops secrets/paperless.yaml"
nix-shell -p sops --run "sops secrets/firefly.yaml"
```

### 4. Deploy Age Key to Hosts

Copy the age private key to each host:

```bash
# For hab-lab
ssh hab-lab@10.0.0.6 "sudo mkdir -p /var/lib/sops-nix"
scp ~/.config/sops/age/keys.txt hab-lab@10.0.0.6:/tmp/keys.txt
ssh hab-lab@10.0.0.6 "sudo cp /tmp/keys.txt /var/lib/sops-nix/key.txt && sudo chmod 400 /var/lib/sops-nix/key.txt"

# For warframe (local machine)
sudo mkdir -p /var/lib/sops-nix
sudo cp ~/.config/sops/age/keys.txt /var/lib/sops-nix/key.txt
sudo chmod 400 /var/lib/sops-nix/key.txt
```

### 5. Deploy Configuration

```bash
# Build and switch
nixos-rebuild switch --flake .#hab-lab
# or for warframe
nixos-rebuild switch --flake .#warframe
```

## File Structure

```
hab-nixos/
├── .sops.yaml              # Age key configuration
├── secrets/
│   ├── users.yaml          # User passwords (encrypted)
│   ├── nextcloud.yaml      # Nextcloud secrets (encrypted)
│   ├── paperless.yaml      # Paperless secrets (encrypted)
│   ├── firefly.yaml        # Firefly-III secrets (encrypted)
│   └── *.example.yaml      # Templates (not encrypted)
├── modules/
│   └── secrets/
│       └── sops.nix        # Sops configuration module
└── hosts/
    ├── hab-lab/
    │   └── secrets.nix     # Host-specific secret config
    └── warframe/
        └── secrets.nix     # Host-specific secret config
```

## Managing Secrets

### Editing Secrets

```bash
# Edit an encrypted file (decrypts, opens editor, re-encrypts on save)
nix-shell -p sops --run "sops secrets/users.yaml"
```

### Viewing Secrets

```bash
# View decrypted content
nix-shell -p sops --run "sops -d secrets/users.yaml"

# View a specific key
nix-shell -p sops --run "sops -d --extract '["users"]["root"]["hashed-password"]' secrets/users.yaml"
```

### Adding New Secrets

1. Add the secret to the appropriate YAML file:
   ```bash
   nix-shell -p sops --run "sops secrets/nextcloud.yaml"
   ```

2. Reference it in your NixOS configuration:
   ```nix
   sops.secrets."nextcloud/my-new-secret" = {
     sopsFile = ./../secrets/nextcloud.yaml;
     key = "nextcloud/my-new-secret";
     owner = "nextcloud";
     group = "nextcloud";
   };
   ```

3. Use the secret:
   ```nix
   services.nextcloud.config.mySecretFile = 
     config.sops.secrets."nextcloud/my-new-secret".path;
   ```

### Creating a New Secret File

1. Create the template:
   ```bash
   cp secrets/users.example.yaml secrets/newservice.yaml
   ```

2. Edit and encrypt:
   ```bash
   nix-shell -p sops --run "sops secrets/newservice.yaml"
   ```

3. Reference in modules:
   ```nix
   sops.secrets."newservice/secret-name" = {
     sopsFile = ./../secrets/newservice.yaml;
     key = "newservice/secret-name";
   };
   ```

## Secret Options

Each secret can have the following options:

```nix
sops.secrets."path/to/secret" = {
  # Path to the encrypted YAML file
  sopsFile = ./../secrets/service.yaml;
  
  # Key path within the YAML file
  key = "service/secret-name";
  
  # Owner of the decrypted file (default: root)
  owner = "service-user";
  
  # Group of the decrypted file (default: root)
  group = "service-group";
  
  # File permissions (default: "0400")
  mode = "0400";
  
  # Whether the secret is needed for user creation
  # Set to true for user passwords
  neededForUsers = false;
};
```

## User Passwords

User passwords require special handling because they're needed during user creation, before the main sops service runs.

```nix
sops.secrets."users/username/hashed-password" = {
  sopsFile = ../../secrets/users.yaml;
  key = "users/username/hashed-password";
  neededForUsers = true;  # Important!
};

users.users.username = {
  hashedPasswordFile = config.sops.secrets."users/username/hashed-password".path;
};
```

### Generating Hashed Passwords

```bash
# Using mkpasswd
nix-shell -p mkpasswd --run "mkpasswd -m yescrypt"

# Using openssl
openssl passwd -6 "your-password"
```

## Troubleshooting

### Secrets Not Decrypted

1. Check the age key exists:
   ```bash
   ls -la /var/lib/sops-nix/key.txt
   ```

2. Check the key permissions:
   ```bash
   sudo chmod 400 /var/lib/sops-nix/key.txt
   ```

3. Verify the public key in `.sops.yaml` matches the private key:
   ```bash
   nix-shell -p age --run "age-keygen -y /var/lib/sops-nix/key.txt"
   ```

### Service Can't Read Secret

1. Check the secret exists:
   ```bash
   ls -la /run/secrets/
   ```

2. Check ownership:
   ```bash
   ls -la /run/secrets/nextcloud/admin-password
   ```

3. Verify the service user can read it:
   ```bash
   sudo -u nextcloud cat /run/secrets/nextcloud/admin-password
   ```

### Re-encrypting After Key Change

If you change the age key, re-encrypt all secrets:

```bash
# Update .sops.yaml with new public key
# Then re-encrypt each file
nix-shell -p sops --run "sops updatekeys secrets/users.yaml"
nix-shell -p sops --run "sops updatekeys secrets/nextcloud.yaml"
# etc.
```

## Security Best Practices

1. **Never commit unencrypted secrets** - The `.gitignore` is configured to help prevent this
2. **Backup your age key** - Store it securely offline
3. **Use strong passwords** - Generate with `mkpasswd -m yescrypt`
4. **Limit secret access** - Set appropriate owner/group/mode for each secret
5. **Rotate secrets periodically** - Especially after any security incident
6. **Use separate keys for production** - Consider separate age keys for different environments

## Integration with Services

### Nextcloud

```nix
sops.secrets."nextcloud/admin-password" = {
  owner = config.services.nextcloud.user;
  group = config.services.nextcloud.group;
  sopsFile = ./../secrets/nextcloud.yaml;
};

services.nextcloud.config.adminpassFile = 
  config.sops.secrets."nextcloud/admin-password".path;
```

### Paperless-ngx

```nix
sops.secrets."paperless/password" = {
  owner = "paperless";
  sopsFile = ./../secrets/paperless.yaml;
};

services.paperless.passwordFile = 
  config.sops.secrets."paperless/password".path;
```

### Firefly-III

```nix
sops.secrets."firefly/app-key" = {
  owner = "firefly-iii";
  sopsFile = ./../secrets/firefly.yaml;
};

services.firefly-iii.settings.APP_KEY_FILE = 
  config.sops.secrets."firefly/app-key".path;