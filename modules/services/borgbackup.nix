{ config, lib, pkgs, ... }:
let
  service = "borgbackup";
  cfg = config.homelab.services.${service};
  hostName = config.networking.hostName;
  # Files the job service bootstrap writes (ProtectSystem=strict allows only these).
  sshKey = "/root/.ssh/id_borg_${hostName}";
  passphraseFile = "/var/lib/borgbackup/${hostName}.passphrase";
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    repo = lib.mkOption {
      type = lib.types.str;
      description = ''
        Borg repository to back up to (ssh:// or user@host:path form).
        PLACEHOLDERS until the backup server is provisioned — replace
        <BACKUP_USER> and <BACKUP_IP>, then install the host's public key on
        the server restricted to `borg serve --restrict-to-path` (see
        plans/borg-backup-plan.md).
      '';
      default = "ssh://<BACKUP_USER>@<BACKUP_IP>/var/backups/borg/${hostName}";
    };
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/etc" ];
      description = ''
        Directories to back up. Start small and grow: service data lives at
        /tank/nextcloud (Nextcloud), /var/lib/mealie (Mealie), /tank/Paperless
        and /var/lib/paperless (Paperless).
      '';
    };
    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Exclude patterns passed to borg create.";
    };
    startAt = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "systemd OnCalendar schedule for the backup timer.";
    };
    persistentTimer = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the backup immediately if a scheduled run was missed.";
    };
    compression = lib.mkOption {
      type = lib.types.str;
      default = "auto,zstd,6";
      description = "Borg compression setting.";
    };
    sshHostKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Backup server SSH host key line (e.g. `<host> ssh-ed25519 AAAA...`)
        to pin in root's known_hosts, turning on strict host key checking.
        When unset the first connection trusts whatever key the server
        presents (`StrictHostKeyChecking=accept-new`) — verify the host
        fingerprint manually the first time.
      '';
    };
    prune.keep = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.int (lib.types.strMatching "[[:digit:]]+[Hdwmy]"));
      default = {
        within = "1d";
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      description = "Archive retention passed to borg prune.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.borgbackup.jobs.${hostName} = {
      repo = cfg.repo;
      paths = cfg.paths;
      exclude = cfg.exclude;
      startAt = cfg.startAt;
      persistentTimer = cfg.persistentTimer;
      compression = cfg.compression;
      prune.keep = cfg.prune.keep;
      archiveBaseName = hostName;
      doInit = true;

      # Client-side encrypted (repokey). Passphrase lives outside the Nix
      # store; the preHook below generates it on first run.
      encryption = {
        mode = "repokey-blake2";
        passCommand = "${pkgs.coreutils}/bin/cat ${passphraseFile}";
      };

      # Fail fast on missing key authorization; keepalives avoid stuck borg
      # locks on flaky links. Host key checking: strict when pinned via
      # sshHostKey, otherwise trust-on-first-use.
      environment.BORG_RSH =
        "ssh -i ${sshKey} -oBatchMode=yes"
        + " -oStrictHostKeyChecking=${
          if cfg.sshHostKey != null then "yes" else "accept-new"
        }"
        + " -oServerAliveInterval=10 -oServerAliveCountMax=30";
      extraArgs = [ "--lock-wait 600" ];

      readWritePaths = [
        "/root/.ssh"
        "/var/lib/borgbackup"
      ];

      preHook = ''
        # Generate the repo encryption passphrase on first run (root-only).
        if [ ! -f ${passphraseFile} ]; then
          ${pkgs.coreutils}/bin/install -d -m 700 /var/lib/borgbackup
          umask 077
          ${pkgs.coreutils}/bin/head -c 48 /dev/urandom | ${pkgs.coreutils}/bin/base64 > ${passphraseFile}
          echo "Generated borg passphrase: ${passphraseFile} (back this file up!)" >&2
        fi

        # Generate the SSH key used to reach the backup server on first run.
        if [ ! -f ${sshKey} ]; then
          ${pkgs.coreutils}/bin/install -d -m 700 /root/.ssh
          ssh-keygen -q -t ed25519 -N "" -f ${sshKey} -C "borg-backup@${hostName}"
        fi
      '';

      postInit = ''
        echo "== borg repository initialized =="
        echo "Passphrase (save this file, it cannot be recovered): ${passphraseFile}"
        echo "Install this public key on the backup server's authorized_keys:"
        ${pkgs.coreutils}/bin/cat ${sshKey}.pub
      '';
    };

    # ReadWritePaths must exist before the unit starts (systemd >= 257 fails
    # mount namespacing otherwise); the preHook `install -d` is only a
    # fallback. A pinned host key lands in /root/.ssh/known_hosts.
    systemd.tmpfiles.settings."borgbackup-job-${hostName}" = {
      "/var/lib/borgbackup".d = {
        mode = "0700";
        user = "root";
        group = "root";
      };
      "/root/.ssh".d = {
        mode = "0700";
        user = "root";
        group = "root";
      };
    } // lib.optionalAttrs (cfg.sshHostKey != null) {
      "/root/.ssh/known_hosts".f = {
        mode = "0600";
        user = "root";
        group = "root";
        argument = cfg.sshHostKey;
      };
    };
  };
}
