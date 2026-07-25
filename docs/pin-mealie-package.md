# Pin Mealie Package to Specific Git Commit

## Status

| Step | Status | Notes |
|------|--------|-------|
| Plan created | ✅ Done | See sections below |
| Overlay added to hab-lab config | ✅ Done | `hosts/hab-lab/configuration.nix` |
| Fill in sha256 hash | ⏳ Pending | Requires first build to get correct hash |
| Flake eval / build test | ⏳ Pending | Verify no syntax or dependency errors |
| Deploy to hab-lab | ⏳ Pending | `nixos-rebuild switch --flake .#hab-lab` |

## Background

The `mealie` package in nixpkgs is outdated. We need to pin it to a newer commit from the upstream repo for `hab-lab-1`, the only host that runs it.

## Target

- **Repo:** `https://github.com/mealie-recipes/mealie.git`
- **Commit:** `e22b8e7`
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
        rev   = "e22b8e7";          # Exact commit hash — pins the source
        sha256 = "sha256-????";     # Content hash — fill in after first build fails
      };

      # If the new version number differs from what nixpkgs expects,
      # you may also need to update:
      # version = "x.y.z";

      # If dependencies changed (new python packages, new build tools),
      # you may need to update those too:
      # buildInputs = old.buildInputs ++ [ final.someNewDep ];
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

On the first build, Nix will fail because the `sha256` is a placeholder. The error message will include the correct hash:

```
hash mismatch in fixed-output derivation '/nix/store/...-mealie-...':
  specified: sha256-????
  got:       sha256-ABCdef123456...
```

Copy the `got` hash and paste it into the overlay:

```nix
sha256 = "sha256-ABCdef123456...";
```

Then rebuild — it should succeed.

---

## Rollback

If the pinned version causes issues, remove the `nixpkgs.overlays` block from `hosts/hab-lab/configuration.nix` and rebuild. NixOS rollback also works:

```bash
nixos-rebuild switch --rollback
```
