# Borg Backups for hab-lab-1 — Plan & Status

> Status snapshot: 2026-08-10. Implementation is **written and config-verified**;
> remaining steps are the pending tmpfiles-rendering check and the deployment
> checklist at the bottom (needs the real server).

## What this is

Daily, encrypted, deduplicated backups of **hab-lab-1** to a remote server via
the NixOS `services.borgbackup` module. The server is **not provisioned yet** —
the repo URL ships with `<BACKUP_USER>` / `<BACKUP_IP>` placeholders. The server
gets **write-only access** (no shell, no visibility outside the backup tree).

Full design doc: `plans/borg-backup-plan.md`.

## Access contract (write-only server access)

Server `~/.ssh/authorized_keys` entry (when the server exists):

```
command="borg serve --restrict-to-path /var/backups/borg",restrict ssh-ed25519 <PUBKEY> borg-backup@hab-lab-1
```

The `restrict` key option + forced `borg serve` command = the key can only
create/append/prune archives under `/var/backups/borg`. Repos are
client-side encrypted (`repokey-blake2`), so the server never sees plaintext.

## Files changed

| File | Status | Content |
|---|---|---|
| `modules/services/borgbackup.nix` | NEW | `homelab.services.borgbackup` module (dendritic pattern, mirrors `paperless-ngx.nix`) |
| `modules/services/serverdefault.nix` | MODIFIED (+1 line) | imports `./borgbackup.nix` |
| `hosts/hab-lab/configuration.nix` | MODIFIED (+15 lines) | enables the module, placeholder repo, commented example paths |
| `plans/borg-backup-plan.md` | NEW | full design doc + server setup options + checklist |
| `BorgPlan.md` | NEW | this status/handoff file |

Other modified files (`README.md`, `docs/networking.md`, `flake.lock`,
`warframe/*`, `desktop/*`, `nextcloud.nix`) were already dirty in the working
tree before this work — not touched by me.

## Module behavior (verified by evaluation against pinned nixpkgs rev 70ce234)

- Job `borgbackup-job-hab-lab-1` + timer `borgbackup-job-hab-lab-1.timer`
  (`OnCalendar=daily`, `Persistent=true`, waits on `network-online.target`).
- `repo = "ssh://<BACKUP_USER>@<BACKUP_IP>/var/backups/borg/hab-lab-1"` (placeholder).
- `paths = [ "/etc" ]` by default — small safe start. Commented example in host
  config for the real targets:
  - `/tank/nextcloud` (Nextcloud data)
  - `/var/lib/mealie` (Mealie recipes)
  - `/tank/Paperless` + `/var/lib/paperless` (Paperless documents/config)
- `encryption = repokey-blake2`; passphrase **auto-generated on first run**
  (48 random bytes) at `/var/lib/borgbackup/hab-lab-1.passphrase` (mode 600,
  never in the Nix store). **Back this file up — it cannot be recovered.**
- SSH key **auto-generated on first run** at `/root/.ssh/id_borg_hab-lab-1`
  (ed25519). The `.pub` is what gets installed server-side.
- `BORG_RSH` = `ssh -i /root/.ssh/id_borg_hab-lab-1 -oBatchMode=yes
  -oStrictHostKeyChecking=accept-new -oServerAliveInterval=10
  -oServerAliveCountMax=30` (fail-fast, keepalives against stuck locks).
- `extraArgs = [ "--lock-wait 600" ]` (same stuck-lock hardening).
- `compression = auto,zstd,6`; prune keeps `1d` + 7 daily + 4 weekly + 6 monthly;
  `.failed` archive suffix; `doInit = true`; `archiveBaseName = "hab-lab-1"`.
- Options exposed by the module: `enable`, `repo`, `paths`, `exclude`,
  `startAt`, `persistentTimer`, `compression`, `prune.keep`, `sshHostKey`
  (pins the server host key in root's known_hosts → strict host key checking;
  unset = trust-on-first-use).

## Verification done

All with the store's nix 2.35.1 (`/nix/var/nix/profiles/per-user/root/profile-1-link/bin/nix`)
against the flake's pinned nixpkgs (26.11, rev 70ce234):

- [x] `config.services.borgbackup.jobs.hab-lab-1` evaluates — all values as designed.
- [x] Generated service unit: correct `BORG_REPO`/`BORG_RSH`/`BORG_PASSCOMMAND`,
      `ProtectSystem=strict` + `ReadWritePaths=/root/.ssh,/var/lib/borgbackup`,
      User/Group root.
- [x] Generated timer unit: `OnCalendar=daily`, `Persistent=true`, network-online deps.
- [x] Generated backup shell script realized and read end-to-end: passphrase
      bootstrap → ssh-keygen bootstrap → `borg init --encryption repokey-blake2`
      → `borg create --compression auto,zstd,6` on `/etc` → rename off `.failed`
      → prune `--keep-daily=7 --keep-monthly=6 --keep-weekly=4 --keep-within=1d`
      `--glob-archives 'hab-lab-1*'` → compact.
- [x] Full `config.system.build.toplevel.drvPath` for hab-lab evaluates clean
      (module assertions pass).
- [x] `sshHostKey` both branches: default `accept-new` / pinned `yes` +
      known_hosts tmpfiles entry (verified via `extendModules` override).
- [ ] **NOT yet verified**: rendered `tmpfiles.d/borgbackup-job-hab-lab-1.conf`
      file content (ordering of `d /root/.ssh` before `f /root/.ssh/known_hosts`
      is expected from sorted attrset order, but the file wasn't realized).
      Low risk — settings attrset itself is confirmed correct.

## Review (agent pass) — findings & resolutions

Reviewer findings (all 4 addressed):

1. **MAJOR — ReadWritePaths dirs not pre-created** (systemd ≥ 257 fails mount
   namespacing if a ReadWritePaths dir doesn't exist; the preHook could never
   run). **Fixed**: module now declares
   `systemd.tmpfiles.settings."borgbackup-job-<host>"` creating
   `/var/lib/borgbackup` and `/root/.ssh` (0700 root). preHook `install -d`
   kept as fallback.
2. **MINOR — TOFU host-key acceptance** on first connect. **Fixed**: new
   `sshHostKey` option pins the server key (strict checking) when set;
   default stays trust-on-first-use, documented.
3. **MINOR — plan checklist was self-contradictory** (pubkey install listed
   before the key exists). **Fixed**: checklist reordered — run once to
   generate key/passphrase (fails at SSH, expected), install pubkey, run again
   to init.
4. **NIT — daily failing timer until server provisioned** (deliberate,
   documented as the visible "not provisioned yet" signal; no alerting).
   Left as-is.

## Where it stands / next steps

- Everything is implemented and evaluates. The only outstanding verification
  item is the tmpfiles conf render (trivial, see above).
- Nothing has been deployed or committed. Changes are uncommitted in the
  working tree (`git diff` shows the 3 files above; new files untracked).
- The plan's Bring-Up Checklist (bottom of `plans/borg-backup-plan.md`)
  is the deploy path once the server exists:
  1. Replace `<BACKUP_USER>`/`<BACKUP_IP>` in `hosts/hab-lab/configuration.nix`
     (+ add paths when ready), `nixos-rebuild switch --flake .#hab-lab`.
  2. Provision server with `command="borg serve --restrict-to-path /var/backups/borg",restrict`
     key line (options A/B in the plan).
  3. `systemctl start borgbackup-job-hab-lab-1` once → generates key +
     passphrase, fails at SSH (expected).
  4. Install `cat /root/.ssh/id_borg_hab-lab-1.pub` server-side.
  5. Start again → repo initialized; **save the passphrase file**.
  6. (Optional) pin host key via `sshHostKey`; verify with
     `borg list --rsh 'ssh -i /root/.ssh/id_borg_hab-lab-1' <repo>`.
