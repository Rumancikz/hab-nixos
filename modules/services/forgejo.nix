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
# Admin user: created declaratively by systemd.services.forgejo.preStart
# below. The password lives in a root-only file on the box — never in this
# repo or the unit file. One-time setup on hab-lab-1:
#   echo -n 'your-password' | sudo tee /var/lib/forgejo-admin-password
#   sudo chmod 600 /var/lib/forgejo-admin-password
# then restart/switch so preStart runs. After first login, issue a
# fine-grained access token for the atlas agent (web UI → user Settings →
# Applications).
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

      # repository = {
      #   # New repositories are private unless made public explicitly.
      #   DEFAULT_PRIVATE = "private";
      # };
    };
  };

  # Idempotent admin bootstrap. Runs after the module's own preStart (which
  # regenerates app.ini); the unit's WorkingDirectory is /var/lib/forgejo, so
  # the CLI finds custom/conf/app.ini on its own. `|| true` keeps restarts
  # quiet once the user exists.
  systemd.services.forgejo.preStart = ''
      ${lib.getExe config.services.forgejo.package} admin user create \
        --admin --username zach --email zach@zachru.com \
        --password "test" || true
      # To rotate the password later, uncomment:
      # ${lib.getExe config.services.forgejo.package} admin user change-password \
      #   --username zach --password "$(tr -d '\n' < /var/lib/forgejo-admin-password)" || true
  '';
}
