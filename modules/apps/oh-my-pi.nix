# Oh My Pi — sandboxed coding agent in a rootless podman container.
#
# Pins the v18.0.0 release binary (modeled on
# https://github.com/Rumancikz/omp-nix, which tracks the latest release
# automatically; we pin an explicit version), wraps it in a minimal OCI
# image built from nixpkgs, and runs it in a rootless podman container
# owned by a dedicated `omp` system user (container root maps to host
# `omp`, which has no sudo rights — a container escape cannot escalate
# on the host):
#
#   sudo -u omp podman exec -it omp omp
#   sudo -u omp podman exec -it omp bash
#
# From another machine on the tailnet (e.g. the laptop):
#   ssh -t atlas@hab-atlas omp-attach
# attaches to (or starts) a tmux session running the agent; the session
# survives SSH disconnects — detach with Ctrl-b d, re-attach anytime.
#
# Hardening (the agent runs unattended): all capabilities dropped, pids
# limit, read-only rootfs with tmpfs /tmp and /root, default seccomp and
# no-new-privileges (rootless podman defaults), no published ports.
#
# The container idles (sleep infinity) and starts at boot. Project code
# lives in /srv/omp (mounted at /workspace); omp state/config lives in
# /var/lib/omp/.omp (mounted at /root/.omp), so sessions and credentials
# persist across restarts and rebuilds.
#
# Git forge access (git.zachru.com, Forgejo on hab-lab): the agent
# authenticates with a personal access token kept in
# /var/lib/omp/git-credentials (0600 omp:omp; mounted read-only at
# /root/.git-credentials). credential.helper=store and the commit
# identity are injected via GIT_CONFIG_* env vars because /root is
# tmpfs. One-time setup on the box:
#   echo "https://zach:<token>@git.zachru.com" | sudo tee /var/lib/omp/git-credentials
#   sudo chown omp:omp /var/lib/omp/git-credentials
#   sudo chmod 600 /var/lib/omp/git-credentials
# (tmpfiles keeps a 0600 placeholder so the container boots before that)
#
# Inference: the agent runs against the local llama.cpp (llama-swap)
# server at 10.0.0.155:8080 via LLAMA_CPP_BASE_URL (set below). omp's
# built-in `llama.cpp` provider auto-discovers the server's models and
# needs no API key; the models.yml baked in below (replicated from the
# laptop's) adds real metadata — 256k context and xhigh thinking for
# qwen3-8-4, where auto-discovery alone would assign conservative
# defaults. Pick a model in the TUI (alt+p) — the choice persists in
# /var/lib/omp/.omp.
#
# One-time migration of existing state (on the box, before or after the
# first boot of the new generation):
#   sudo cp -a /home/atlas/.omp/. /var/lib/omp/.omp/
#   sudo chown -R omp:omp /var/lib/omp/.omp
{ config, lib, pkgs, ... }:

let
  ohMyPi = pkgs.stdenv.mkDerivation {
    pname = "oh-my-pi";
    version = "18.0.0";

    src = pkgs.fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v18.0.0/omp-linux-x64";
      sha256 = "69065aefe916fe28a09a4a1396446f16a776b5b56af0867cb4db0f452d842851";
    };

    dontUnpack = true;
    dontBuild = true;

    # The release artifact is a Bun single-file executable: the JS bundle
    # lives in a `.bun` PROGBITS section that the Bun runtime locates by
    # reading its own executable image. Stripping (or letting fixupPhase
    # patch the ELF) breaks that lookup, so suppress both. Setting the
    # interpreter with patchelf is safe: the `.bun` bytes survive intact.
    dontStrip = true;
    dontPatchELF = true;

    nativeBuildInputs = [ pkgs.patchelf ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      install -m755 $src $out/bin/omp
      patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} $out/bin/omp
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "A coding agent with the IDE wired in";
      homepage = "https://github.com/can1357/oh-my-pi";
      license = licenses.mit;
      mainProgram = "omp";
      platforms = [ "x86_64-linux" ];
    };
  };

  # Toolset available to the agent inside the container. GNU sed/grep were
  # removed from nixpkgs; grep comes from gnugrep, sed from busybox.
  tools = [
    pkgs.bash
    pkgs.busybox
    pkgs.cacert
    pkgs.coreutils
    pkgs.curl
    pkgs.findutils
    pkgs.git
    pkgs.gawk
    pkgs.gnugrep
    pkgs.ripgrep
  ];

  # Model metadata for the local llama.cpp server, replicated from the
  # laptop's ~/.omp/agent/models.yml: qwen3-8-4 gets its real 256k context
  # window and xhigh thinking ladder (auto-discovery alone assigns
  # conservative defaults). Bound read-only into the container's agent dir
  # (see container volumes).
  ompModelsYml = pkgs.writeText "omp-models.yml" ''
    providers:
      llama.cpp:
        baseUrl: http://10.0.0.155:8080/v1
        api: openai-responses
        auth: none
        discovery:
          type: llama.cpp
        modelOverrides:
          qwen3-8-4:
            input: [text, image]
            contextWindow: 262144
            thinking:
              mode: effort
              efforts: [low, medium, xhigh]
              defaultLevel: xhigh
  '';

  # The container rootfs. Assembled explicitly: `streamLayeredImage`
  # lndir-merges every `contents` tree at the rootfs root (e.g. busybox's
  # whole fake-root layout would leak in), so we build the exact tree we
  # want in one derivation and pass it as the sole contents entry.
  rootfs = pkgs.runCommand "oh-my-pi-rootfs" {
    preferLocalBuild = true;
  } ''
    mkdir -p $out/bin $out/usr/bin $out/usr/local/bin $out/etc/ssl/certs $out/tmp $out/root $out/workspace

    # Expose every tool on the first PATH entry. List order matters: later
    # packages win, so the GNU tools (coreutils, findutils, gawk, gnugrep)
    # shadow busybox applets where they exist; busybox still provides sed
    # and any fallback.
    for pkg in ${lib.concatStringsSep " " ([ ohMyPi ] ++ tools)}; do
      [ -d "$pkg/bin" ] || continue
      for f in "$pkg"/bin/*; do
        ln -sf "$f" "$out/usr/local/bin/$(basename "$f")"
      done
    done

    # Shims for absolute-path lookups.
    ln -s ${pkgs.bash}/bin/bash $out/bin/bash
    ln -s ${pkgs.bash}/bin/sh $out/bin/sh
    ln -s ${pkgs.coreutils}/bin/env $out/usr/bin/env

    # Minimal /etc; podman provides hosts/hostname/resolv.conf at runtime.
    printf 'root:x:0:0:root:/root:/bin/bash\n' > $out/etc/passwd
    printf 'root:x:0:\n' > $out/etc/group
    printf 'passwd: files\ngroup: files\nshadow: files\n' > $out/etc/nsswitch.conf
    ln -s ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/certs/ca-certificates.crt
    ln -s /proc/mounts $out/etc/mtab
  '';

  image = pkgs.dockerTools.streamLayeredImage {
    name = "oh-my-pi";
    tag = ohMyPi.version;
    contents = [ rootfs ];

    config = {
      Env = [
        "PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        "HOME=/root"
        "TERM=xterm-256color"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
      WorkingDir = "/workspace";
    };
  };
in
{
  # Dedicated sandbox user: no wheel, no sudo — if the container is ever
  # escaped, the attacker lands on an account with no escalation path on
  # the host. The bash shell allows `sudo -iu omp` for interactive use.
  users = {
    groups.omp = { };
    users.omp = {
      isSystemUser = true;
      group = "omp";
      home = "/var/lib/omp";
      createHome = true;
      shell = "${pkgs.bash}/bin/bash";
      # Rootless podman needs the user runtime dir (/run/user/<uid>) to
      # survive logouts; the container service also RequiresMountsFor it.
      linger = true;
    };
    # Owner of the workspace; can inspect (not write) the agent's output.
    users.atlas.extraGroups = [ "omp" ];
  };

  # Host-side workflow tooling. tmux keeps agent sessions alive across SSH
  # disconnects; `omp-attach [name]` attaches to — or starts — the tmux
  # session that drives the `name` container (session and container share
  # a name, so this extends to multiple containers unchanged).
  environment.systemPackages = [
    pkgs.tmux
    (pkgs.writeShellScriptBin "omp-attach" ''
      set -e
      name="$1"; [ -n "$name" ] || name=omp
      if tmux has-session -t "=$name" 2>/dev/null; then
        exec tmux attach-session -t "=$name"
      fi
      # New session: agent TUI in window 0, host shell in window 1
      # (for `journalctl -u podman-omp`, `sudo -u omp podman logs omp`, …).
      # -c / : omp cannot enter /home/atlas (0700) and sudo keeps the CWD.
      # (Bare $ is literal in Nix strings, so the bash variables below
      # pass through untouched.)
      cmd="sudo -u omp podman exec -it $name omp"
      tmux new-session -d -s "$name" -c / "$cmd"
      tmux new-window -t "=$name"
      exec tmux attach-session -t "=$name"
    '')
  ];

  # Host-side bind sources (podman errors if they don't exist):
  # /srv/omp = project code the agent works on (-> /workspace),
  # /var/lib/omp/.omp = agent state/credentials (-> /root/.omp),
  # /var/lib/omp/git-credentials = Forgejo token (-> /root/.git-credentials).
  systemd.tmpfiles.rules = [
    "d /srv/omp 0750 omp omp -"
    "d /var/lib/omp/.omp 0700 omp omp -"
    "d /var/lib/omp/.omp/agent 0700 omp omp -"
    # Placeholder for the Forgejo token (filled in by hand — see header).
    # `f` creates it if missing and leaves an existing file untouched.
    "f /var/lib/omp/git-credentials 0600 omp omp -"
  ];

  # Let atlas drive the sandbox without a password, e.g.
  #   sudo -u omp podman exec -it omp omp
  # Scoped to omp's rootless podman only — no host privilege involved.
  security.sudo.extraRules = [{
    users = [ "atlas" ];
    runAs = "omp";
    commands = [
      {
        command = "/run/current-system/sw/bin/podman";
        options = [ "NOPASSWD" ];
      }
    ];
  }];

  virtualisation.oci-containers = {
    backend = "podman";
    # Note: this module enables virtualisation.podman itself.

    containers.omp = {
      # Must match the name:tag the image stream loads.
      image = "oh-my-pi:${ohMyPi.version}";
      imageStream = image;

      # Rootless: the service runs podman as `omp`, so container root is
      # the host `omp` account (files the agent creates are omp-owned).
      podman.user = "omp";

      autoStart = true;
      workdir = "/workspace";
      volumes = [
        "/srv/omp:/workspace"
        "/var/lib/omp/.omp:/root/.omp"
        # Forgejo token for git.zachru.com (0600 omp:omp on the host).
        "/var/lib/omp/git-credentials:/root/.git-credentials:ro"
        # Model metadata for the local server; overlays the /root/.omp bind.
        "${ompModelsYml}:/root/.omp/agent/models.yml:ro"
      ];

      # Local inference: omp's built-in `llama.cpp` provider reads this and
      # auto-discovers the server's models (keyless by design).
      # Git: credential store (reads /root/.git-credentials) + commit
      # identity. /root is tmpfs, so the config rides in env vars instead
      # of a .gitconfig (git 2.31+).
      environment = {
        LLAMA_CPP_BASE_URL = "http://10.0.0.155:8080/v1";
        GIT_CONFIG_COUNT = "4";
        GIT_CONFIG_KEY_0 = "credential.helper";
        GIT_CONFIG_VALUE_0 = "store";
        GIT_CONFIG_KEY_1 = "user.name";
        GIT_CONFIG_VALUE_1 = "atlas-agent";
        GIT_CONFIG_KEY_2 = "user.email";
        GIT_CONFIG_VALUE_2 = "atlas-agent@zachru.com";
      };

      # --- Hardening: the agent runs unattended ---
      # Drop every capability; a coding workload needs none (rootless
      # user-namespace privileges are unaffected by this).
      capabilities."ALL" = false;
      extraOptions = [
        # Fork-bomb / runaway-build protection.
        "--pids-limit=1024"
        # Read-only rootfs: the container is ephemeral (--rm on stop), so
        # nothing can persist in it anyway; this just closes the door.
        "--read-only"
        # Writable scratch. /tmp is noexec (no binaries off /tmp); /root
        # keeps exec so cargo/npm installs under $HOME work. The
        # /root/.omp bind still overlays the tmpfs.
        "--tmpfs" "/tmp:rw,noexec,nosuid,nodev"
        "--tmpfs" "/root:rw,nosuid,nodev"
      ];

      # Idle forever; drive it with `sudo -u omp podman exec -it omp omp`.
      entrypoint = "${pkgs.busybox}/bin/sleep";
      cmd = [ "infinity" ];
    };
  };
}
