# Plan: Borg backups for hab-lab-1

## Overview

Add daily, encrypted, deduplicated backups of **hab-lab-1** to a remote server
using [BorgBackup](https://www.borgbackup.org/) via the built-in NixOS module
(`services.borgbackup`). The remote server is **not yet provisioned** — the
repository URL ships with placeholders for the server IP and SSH user. The
initial backup set is intentionally small (`/etc`); the service data directories
(Nextcloud, Mealie, Paperless) are staged and documented for the next iteration.

### Access contract: write-only server access

The backup user on the server gets **no shell and no access outside the backup
tree**. Both supported server setups force borg's restricted serve mode via an
OpenSSH forced command plus the `restrict` key option, which disables
port-forwarding, PTY, agent forwarding, and everything else non-essential:

```
command="borg serve --restrict-to-path /var/backups/borg",restrict ssh-ed25519 AAAA... borg-backup@hab-lab-1
```

The key can only create/append/prune archives inside `/var/backups/borg`
(the `--restrict-to-path` grant includes subdirectories, where the repository
lives). The repository itself is client-side encrypted (`repokey-blake2`), so
the server never sees plaintext — it is a write-only storage target.

## Repository Structure After Implementation

```
hab-nixos/
├── hosts/
│   └── hab-lab/
│       └── configuration.nix              # MODIFIED: enable homelab.services.borgbackup
└── modules/
    └── services/
        ├── serverdefault.nix              # MODIFIED: import borgbackup.nix
        └── borgbackup.nix                 # NEW: homelab.services.borgbackup module
```

## New File: `modules/services/borgbackup.nix`

Follows the existing dendritic pattern (see `paperless-ngx.nix`): declares
`options.homelab.services.borgbackup`, applies the config with
`lib.mkIf cfg.enable`.

| Option | Default | Notes |
|---|---|---|
| `enable` | `false` | `mkEnableOption` |
| `repo` | `"ssh://<BACKUP_USER>@<BACKUP_IP>/var/backups/borg/<hostname>"` | **Placeholders** — filled in when the server is provisioned |
| `paths` | `[ "/etc" ]` | Small, safe start; service dirs added later |
| `exclude` | `[ ]` | Passed through to borg `--exclude-from` |
| `startAt` | `"daily"` | systemd `OnCalendar` |
| `persistentTimer` | `true` | Catch up after missed runs |
| `compression` | `"auto,zstd,6"` | Good ratio without crippling the CPU |
| `prune.keep` | `within = "1d"; daily = 7; weekly = 4; monthly = 6;` | Matches the nixpkgs example shape |
| `sshHostKey` | `null` | Server host key line to pin in root's `known_hosts` (enables `StrictHostKeyChecking=yes`). Unset = trust-on-first-use — verify the host fingerprint on the first connection |

Job wiring (all defaults, no per-host config beyond enable/repo):

- Job name `borgbackup-job-<hostname>` — one job per host, reusable by other
  hosts later.
- `encryption = repokey-blake2` with `passCommand = "cat /var/lib/borgbackup/<hostname>.passphrase"`.
  The passphrase is **auto-generated on first run** (48 random bytes, mode 600)
  so no secret ever lands in the world-readable Nix store, and no manual step
  is needed before the first `borg init`. The file must be backed up by the
  operator — losing it makes the repo unrecoverable (reminder printed to the
  journal on init).
- SSH key: auto-generated on first run at `/root/.ssh/id_borg_<hostname>`
  (`ssh-keygen -t ed25519`, no passphrase). The public half is what gets
  installed in the server's `authorized_keys`.
- `BORG_RSH = "ssh -i /root/.ssh/id_borg_<hostname> -oBatchMode=yes -oStrictHostKeyChecking=accept-new -oServerAliveInterval=10 -oServerAliveCountMax=30"`.
  BatchMode fails fast instead of hanging on a password prompt; keepalives
  avoid stuck borg locks on flaky links (borg docs recommendation).
- `extraArgs = [ "--lock-wait 600" ]` — same stuck-lock hardening.
- `readWritePaths = [ "/root/.ssh" "/var/lib/borgbackup" ]` — the job service
  runs with `ProtectSystem=strict`; these two paths are what the bootstrap
  hooks write.
- `archiveBaseName = <hostname>`, `doInit = true` (auto `borg init` on first
  connect), `appendFailedSuffix = true` (default).

## Server-Side Setup (when the server exists)

### Option A — generic OpenSSH server (no NixOS required)

On the server, as the backup user:

1. Create the backup root: `mkdir -p /var/backups/borg`.
2. Append to `~/.ssh/authorized_keys` (one line):
   ```
   command="borg serve --restrict-to-path /var/backups/borg",restrict ssh-ed25519 <PUBKEY> borg-backup@hab-lab-1
   ```
   where `<PUBKEY>` is `cat /root/.ssh/id_borg_hab-lab-1.pub` from hab-lab-1.
3. Optional hardening (borg docs): server `sshd_config` `ClientAliveInterval 10`
   / `ClientAliveCountMax 30`, and set the backup user's shell to `/bin/sh`.

### Option B — NixOS-managed server (when it joins this flake)

```nix
services.borgbackup.repos.hab-lab-1 = {
  path = "/var/backups/borg/hab-lab-1";
  authorizedKeys = [ "<PUBKEY>" ];
};
```

This generates the same forced-command `authorized_keys` line
(`cd <path> && borg serve --restrict-to-repository .`, `restrict`), creates
the repo directory with correct ownership, and adds a system user. If this
option is used, the client repo can be shortened to `user@host:.` (relative
path — the NixOS module's documented client form).

## Bring-Up Checklist

Order matters — the SSH key is generated by the job itself (preHook), so
the first run generates the key and fails at the SSH step; the second run
succeeds once the key is installed server-side.

1. In `hosts/hab-lab/configuration.nix`, replace `<BACKUP_USER>`/`<BACKUP_IP>`
   in `homelab.services.borgbackup.repo`. Optionally add backup paths (see
   below), then `nixos-rebuild switch --flake .#hab-lab`.
2. Provision the server (Option A or B above) with a placeholder pubkey or
   with no key yet — the exact key gets installed in step 4.
3. Run the job once: `systemctl start borgbackup-job-hab-lab-1`. This
   generates `/root/.ssh/id_borg_hab-lab-1` (plus `.pub`) and the passphrase
   file, then fails at the SSH connect step — expected, since the key isn't
   authorized yet. (Until the server exists, every timer run fails at the
   SSH/DNS step the same way — that is the visible "not provisioned yet"
   signal.)
4. Install the public key server-side (Option A or B),
   `cat /root/.ssh/id_borg_hab-lab-1.pub` on hab-lab-1.
5. Run the job again: `systemctl start borgbackup-job-hab-lab-1`. First
   successful connect initializes the repo and prints the passphrase path and
   the installed public key to the journal.
6. **Save `/var/lib/borgbackup/hab-lab-1.passphrase` somewhere safe** — it
   cannot be recovered. See `journalctl -u borgbackup-job-hab-lab-1`.
7. Optional: pin the server host key via
   `homelab.services.borgbackup.sshHostKey` (the server's `ssh-keyscan` line)
   instead of the default trust-on-first-use.
8. Verify: `borg list --rsh 'ssh -i /root/.ssh/id_borg_hab-lab-1' <repo>` or
   `systemctl status borgbackup-job-hab-lab-1` / check the journal for
   `Completed archive ...`.

## Next Iteration: Service Data Directories

| Service | Path(s) | Notes |
|---|---|---|
| Nextcloud | `/tank/nextcloud` | `nextcloud.datadir` in `modules/services/nextcloud.nix`; PostgreSQL DB lives in `/var/lib/postgresql` — DB backup needs a `pg_dump` preHook (out of scope for the basic version) |
| Mealie | `/var/lib/mealie` | NixOS default data dir (SQLite) |
| Paperless | `/tank/Paperless` (`Documents/` + `Import/`), `/var/lib/paperless` | `mediaDir`/`consumptionDir` in `modules/services/paperless-ngx.nix`; config dir holds the SQLite DB |

Additions are one-line `paths` entries in the host config. `/tank` is ZFS —
consider snapshot-based dumps (`dumpCommand`) instead of walking the live tree
once the datasets grow; the module supports both.
