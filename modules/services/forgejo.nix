# Private git forge (Forgejo) for the hab tailnet.
#
# Served exclusively through Caddy as git.zachru.com (see modules/caddy.nix):
# the A record points at the tailnet IP, so the domain is unreachable outside
# the tailnet by construction. Forgejo itself binds 127.0.0.1 only and no
# firewall port is opened — Caddy (443) is the single entry point.
#
# Privacy posture: registration is disabled, sign-in is required to view
# anything, and new repositories default to private.
#
# One-time setup after the first switch (on hab-lab-1) — create the admin:
#   cd /var/lib/forgejo && sudo -u forgejo <store-path>/bin/forgejo \
#     admin user create --username <name> --password '<pw>' \
#     --email <name>@zachru.com --admin
# then issue a fine-grained access token for the atlas agent (web UI →
# user Settings → Applications).
{ config, lib, pkgs, ... }:

{
  services.forgejo = {
    enable = true;
    # Module default package is `forgejo-lts` — keep it (stable release line).

    settings = {
      DEFAULT.APP_NAME = "hab git";

      server = {
        DOMAIN = "git.zachru.com";
        ROOT = "https://git.zachru.com/";
        # Caddy-only exposure: loopback bind, nothing published.
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
      };

      service = {
        # Private instance: no open signup, no anonymous browsing.
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = true;
      };

      repository = {
        # New repositories are private unless made public explicitly.
        DEFAULT_PRIVATE = "private";
      };
    };
  };
}
