{ config, lib, pkgs, ... }:

{
  services.mealie = {
    enable = true;
    # Bind to loopback only — Caddy (modules/caddy.nix) is the sole entry
    # point on this host. Keep the service off the LAN.
    listenAddress = "127.0.0.1";
    port = 9000;

    settings = {
      # Switch to PostgreSQL (managed locally via services.mealie.database.createLocally = true).
      # Requires migrating existing SQLite data first — see the Mealie docs before flipping.
      # DB_ENGINE = "postgres";
    };

    # To run a version ahead of nixpkgs-unstable: nixpkgs tracks mealie within
    # hours of upstream releases, so `nix flake update nixpkgs` usually suffices.
    # If you must pin ahead of nixpkgs anyway, the mealie package is a Python
    # app + separately-built frontend; a pinned src needs a local package
    # definition (copy pkgs/by-name/me/mealie from nixpkgs, pass src/version in)
    # — plain overridePythonAttrs leaves the frontend stale.
  };
}