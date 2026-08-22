# Oh My Pi — pinned release binary (not in nixpkgs).
# Modeled on https://github.com/Rumancikz/omp-nix, which tracks the latest
# release automatically; we pin an explicit version instead.
{ config, pkgs, ... }:

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
in
{
  environment.systemPackages = [ ohMyPi ];
}
