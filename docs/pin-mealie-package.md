# Pin Mealie Package to Specific Git Commit

## Status

| Step | Status | Notes |
|------|--------|-------|
| Plan created | ✅ Done | See sections below |
| Overlay added to hab-lab config | ✅ Done | `hosts/hab-lab/configuration.nix` |
| Resolve full commit SHA | ✅ Done | `e22b8e7` → `e22b8e7b734fb56d6f54a44526005104d3ac8f30` (v3.21.0) |
| Compute sha256 hash | ✅ Done | Used `nix-prefetch-url --unpack` for recursive hash |
| Fix version mismatch (setuptools) | ✅ Done | `substituteInPlace` to relax setuptools pin |
| Flake eval / build test | ✅ Done | `nix build .#nixosConfigurations.hab-lab...` passes |
| Deploy to hab-lab | ✅ Done | `nixos-rebuild switch --flake .#hab-lab` — mealie-3.21.0 running |
| Configure OpenAI integration | ⏳ In Progress | See "OpenAI Integration" section below |

---

## OpenAI Integration (In Progress — July 25, 2026)

### Goal

Enable "import recipe from image" feature (available since v1.12.0, well below our v3.21.0).

### What We Tried

1. **Added OpenAI env vars via `settings`** in `modules/services/mealie.nix`:
   ```nix
   settings = {
     OPENAI_API_BASE = "http://habai:8080/v1";
     OPENAI_API_KEY = "habai";
   };
   ```
   - This created `services.mealie.environment` — **not supported** by the nixpkgs module (error: `option does not exist`)
   - Switched to `settings` — ✅ accepted, env vars appear in `systemctl cat mealie.service`
   - **But**: Admin page still shows "OpenAI Not Ready"

2. **Checked mealie source for env var names**:
   - `grep -rhi "openai" ... | grep -iE "environ|getenv"` returned nothing
   - Mealie docs only list `OPENAI_CUSTOM_PROMPT_DIR` as an env var
   - **Theory**: API key and base URL are configured via the **Group Settings UI**, not env vars

### Current State

- ✅ mealie-3.21.0 is deployed and running (`/nix/store/ap9dvj...mealie-3.21.0`)
- ✅ Env vars `OPENAI_API_BASE` and `OPENAI_API_KEY` are set in the systemd unit
- ❌ Admin page still shows "OpenAI Not Ready"
- ❌ No AI section visible in Group Settings UI

### Remaining Investigation

1. **Check Group Settings UI thoroughly** — the docs say to "visit your group settings" to configure AI. Look for:
   - An "AI" or "OpenAI" tab in Group Settings
   - A settings page at `/admin/groups` or similar
   - Scroll to the bottom — AI settings may be below other sections

2. **Try the documented env var names** — check mealie source for the actual env var names:
   ```bash
   grep -rhi "openai" /nix/store/ap9dvj8sw801wx7g0369q2vm26hk7fms-mealie-3.21.0/ --include="*.py" | grep -iE "environ|getenv|env\[" | head -20
   ```

3. **Check if `settings` maps to env vars correctly** — the nixpkgs module might prefix settings with `ML_` or transform them differently. Verify with:
   ```bash
   systemctl show mealie -p Environment
   journalctl -u mealie --no-pager -n 50 | grep -i openai
   ```

4. **Local OpenAI endpoint** — user has habai (Tailscale MagicDNS) on port 8080. Need to confirm:
   - The endpoint is reachable from hab-lab: `curl http://habai:8080/v1/models`
   - What API key (if any) the endpoint requires

### Related: SSH Setup (Completed)

While working on this, also set up SSH access to warframe from WSL:
- Added `services.openssh` to `hosts/warframe/configuration.nix`
- Added WSL public key to `modules/users/zman/zman.nix`
- Opened port 22 in warframe's firewall
- WSL can now SSH to warframe for remote builds

## Background

The `mealie` package in nixpkgs is outdated. We need to pin it to a newer commit from the upstream repo for `hab-lab-1`, the only host that runs it.

## Target

- **Repo:** `https://github.com/mealie-recipes/mealie.git`
- **Commit:** `e22b8e7b734fb56d6f54a44526005104d3ac8f30` (tag `v3.21.0`)
- **Affected host:** `hab-lab` (only host using mealie)

## Current Setup

- **Module:** `modules/services/mealie.nix` — enables `services.mealie` from nixpkgs
- **Flake input:** `nixpkgs-unstable` branch
- Mealie is imported via `modules/services/serverdefault.nix`

---

## NixOS Concepts (For Learning)

### What is nixpkgs?

`nixpkgs` is the Nix package collection — a massive repository of "derivations" (build instructions) for every package. Your flake pulls it in via `github:NixOS/nixpkgs/nixpkgs-unstable`, meaning you get the latest unstable channel.

Every time you reference `pkgs.mealie` in a module, Nix looks up the `mealie` package inside this nixpkgs snapshot.

### What is a Flake?

A flake is a standardized project layout. Your `flake.nix` declares:
- **inputs** — external dependencies (nixpkgs, disko, home-manager)
- **outputs** — what you produce (nixosConfigurations for each host)

Each host in `nixosConfigurations` is built by combining `nixpkgs` with a set of **modules** (`.nix` config files).

### What is a Module?

A module is a `.nix` file that returns an attribute set of configuration options. For example, `modules/services/mealie.nix` sets `services.mealie.enable = true;`. Modules are the building blocks of your system config.

### What is an Overlay?

An **overlay** is Nix's way of overriding or adding packages inside nixpkgs **without forking the whole repo**. Think of it like a patch layer that sits on top of nixpkgs.

The signature is always `(final: prev: { ... })`:
- `prev` — the original nixpkgs packages (before your changes)
- `final` — the result **after** all overlays are applied (use this to reference other overridden packages)

When you write `prev.mealie.overrideAttrs(...)`, you're saying: "take the existing mealie from nixpkgs, and change some of its build attributes."

### What is `overrideAttrs`?

`overrideAttrs` lets you modify a package's derivation (build recipe). It takes a function `(old: { ... })` where:
- `old` — the original attribute set (src, version, buildInputs, etc.)
- The returned set — merges with `old`, overriding any keys you specify

It's like saying "keep everything about this package the same, except change `src`."

### What is `fetchFromGitHub`?

`fetchFromGitHub` is a built-in Nix function that downloads a GitHub repo at a specific commit. It requires:
- `owner` and `repo` — to locate the repo
- `rev` — the exact git commit hash (pins the source)
- `sha256` — a content hash for reproducibility (Nix verifies the download matches)

The `sha256` is intentionally left blank on first try — Nix will fail the build and print the correct hash for you to copy back in.

---

## Approach

Use a **per-host overlay** in `hosts/hab-lab/configuration.nix` to override the mealie package with one built from the pinned git commit. This keeps the change scoped to `hab-lab` only and avoids modifying the global flake inputs.

### Option A: Flake Overlay (Recommended)

Add a `nixpkgs.overlays` block to `hosts/hab-lab/configuration.nix` that overrides `mealie` with a derivation sourced from the pinned git commit.

### Option B: Flake Input Override

Add a dedicated flake input for the mealie source and use it in an overlay. This is more explicit but adds a top-level input.

**We'll go with Option A** since it's the simplest and most contained.

---

## Steps

1. **Identify the current mealie derivation**
   - Look up the current `mealie` package in nixpkgs source to understand its build type and dependencies
   - Check what `overrideAttrs` fields might need updating (version, dependencies, python packages, etc.)

2. **Create the overlay in `hosts/hab-lab/configuration.nix`**
   - Add a `nixpkgs.overlays` entry that overrides `mealie` with a derivation built from `github:mealie-recipes/mealie?rev=e22b8e7`
   - Adapt the derivation from the current nixpkgs mealie package, updating the `src` to the pinned commit

3. **Update `modules/services/mealie.nix` if needed**
   - If the new commit introduces config option changes, update the module accordingly

4. **Test**
   - Run `nix flake show` to verify the flake evaluates
   - Run `nix build .#hab-lab` (dry eval) to check for build errors
   - Deploy to `hab-lab` and verify the service starts

---

## Example Overlay — Line-by-Line Explanation

Add this block to `hosts/hab-lab/configuration.nix`:

```nix
# nixpkgs.overlays is a list of overlay functions.
# Each overlay can add or modify packages in the pkgs set.
nixpkgs.overlays = [

  # An overlay is a function that takes two arguments:
  #   final — the package set AFTER all overlays are applied
  #   prev  — the package set BEFORE this overlay (original nixpkgs)
  # It returns an attribute set of packages to add/override.
  (final: prev: {

    # We're overriding the "mealie" package.
    # prev.mealie is the original mealie from nixpkgs.
    # .overrideAttrs lets us modify its build attributes.
    mealie = prev.mealie.overrideAttrs (old: {

      # `src` tells Nix where to get the source code.
      # We're replacing it with a fetchFromGitHub call
      # that points to a specific commit instead of whatever nixpkgs uses.
      src = prev.fetchFromGitHub {
        owner = "mealie-recipes";   # GitHub organization
        repo  = "mealie";           # Repository name
        rev   = "e22b8e7b734fb56d6f54a44526005104d3ac8f30";  # Full SHA (v3.21.0)
        sha256 = "sha256-z1FQx5tngM/H78uLcaKENPFl7bWamIC0hPs1r8xM9PA=";  # Recursive hash (base64)
      };

      # If the new version number differs from what nixpkgs expects,
      # you may also need to update:
      version = "3.21.0";

      # If the upstream source has build steps that reference version-specific
      # strings (like setuptools pins), use substituteInPlace to relax them:
      postPatch = ''
        substituteInPlace pyproject.toml --replace "setuptools==83.0.0" "setuptools>=80.0.0" || true
      '';
    });

  })
];
```

### How It All Fits Together

```
flake.nix
  ├── inputs.nixpkgs  →  github:NixOS/nixpkgs/nixpkgs-unstable
  │
  └── outputs.nixosConfigurations.hab-lab
        ├── hosts/hab-lab/configuration.nix     ← YOUR OVERLAY LIVES HERE
        │     └── nixpkgs.overlays = [ ... ]    ← overrides pkgs.mealie
        │
        ├── modules/services/serverdefault.nix  ← imports mealie.nix
        │     └── modules/services/mealie.nix   ← uses services.mealie
        │           └── services.mealie.enable = true
        │                 ↑
        │                 Nix looks up pkgs.mealie → finds your override → uses pinned commit
```

---

## Getting the sha256 Hash

### Why the placeholder approach doesn't always work

The classic approach (use `sha256-????` and let Nix tell you the real hash) works when Nix reaches the **build phase**. But with `fetchFromGitHub`, Nix validates the hash format at **eval time**, so a placeholder fails before any download happens.

### The correct approach: `nix-prefetch-url --unpack`

`fetchFromGitHub` uses `fetchzip` internally, which applies **recursive hashing** over the extracted contents (not the archive file). Use `--unpack` to match:

```bash
nix-prefetch-url --unpack --type sha256 \
  https://github.com/mealie-recipes/mealie/archive/<REV>.tar.gz
```

This outputs a base32 hash. Convert it to base64 for the `sha256` attribute:

```bash
nix hash convert --from nix32 --to base64 sha256:<BASE32_HASH>
```

Then use it as:
```nix
sha256 = "sha256-<BASE64_HASH>";  # e.g. sha256-z1FQx5tngM/H78uLcaKENPFl7bWamIC0hPs1r8xM9PA=
```

### Key concepts from the NixOS Wiki

- **Flat hashing** — hash of the file bytes (default for `fetchurl`)
- **Recursive hashing** — hash of extracted contents after NARing (used by `fetchzip`/`fetchFromGitHub`)
- **`--unpack`** flag on `nix-prefetch-url` — the `fetchzip` equivalent, gives recursive hash
- Hash format for `fetchFromGitHub`: SRI-style `sha256-` prefix + standard base64 (with `=`, `+`, `/`)

---

## Troubleshooting

### "pattern doesn't match anything in file" during build

When pinning to a newer version than nixpkgs expects, build steps may reference strings (like `setuptools==82.0.1`) that don't exist in the new source. Fix with `substituteInPlace` in `postPatch`:

```nix
postPatch = ''
  substituteInPlace pyproject.toml --replace "setuptools==83.0.0" "setuptools>=80.0.0" || true
'';
```

`substituteInPlace` is a standard nixpkgs build tool — use it anywhere you need to patch source files during the build.

### "invalid SRI hash" errors

If you see `invalid SRI hash '...', length X != expected length Y`:
1. Make sure you used `--unpack` for the recursive hash (not plain `nix-prefetch-url`)
2. Convert from base32 to base64 (not base64url) — standard base64 with `=` padding
3. Prefix with `sha256-`

### Short commit hashes

Always resolve short hashes (like `e22b8e7`) to full 40-character SHAs:
```bash
git ls-remote https://github.com/mealie-recipes/mealie.git <SHORT_HASH>
```

---

## Rollback

If the pinned version causes issues, remove the `nixpkgs.overlays` block from `hosts/hab-lab/configuration.nix` and rebuild. NixOS rollback also works:

```bash
nixos-rebuild switch --rollback
```
