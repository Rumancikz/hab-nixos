{ pkgs, ... }:

{
  nixpkgs.config = {
    cudaSupport = true;
    packageOverrides = pkgs: {
      llama-cpp =
          (pkgs.llama-cpp.override {
            cudaSupport = true;
            rocmSupport = false;
            metalSupport = false;
            blasSupport = true;
          }).overrideAttrs
            (oldAttrs: rec {
              version = "8204";
              src = pkgs.fetchFromGitHub {
                owner = "ggml-org";
                repo = "llama.cpp";
                tag = "b${version}";
                hash = "sha256-j3RLNiY6u36qdLah4Zcrac804Ub1wnBtv066PtzBvt0=";
                leaveDotGit = true;
                postFetch = ''
                  git -C "$out" rev-parse --short HEAD > $out/COMMIT
                  find "$out" -name .git -print0 | xargs -0 rm -rf
                '';
              };
              npmDepsHash = "sha256-FKjoZTKm0ddoVdpxzYrRUmTiuafEfbKc4UD2fz2fb8A=";
              cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
                "-DGGML_NATIVE=ON"
                "-DCMAKE_CUDA_ARCHITECTURES=sm_100"
              ];

              preConfigure = ''
                export NIX_ENFORCE_NO_NATIVE=0
                ${oldAttrs.preConfigure or ""}
              '';
            });

      # llama-swap from GitHub releases (same as warframe)
      llama-swap = pkgs.runCommand "llama-swap" { } ''
        mkdir -p $out/bin
        tar -xzf ${
          pkgs.fetchurl {
            url = "https://github.com/mostlygeek/llama-swap/releases/download/v197/llama-swap_197_linux_amd64.tar.gz";
            hash = "sha256-GOP31onCrHvwvutsDXJV0uj+EKKaQdmZfiaBS0tX7Co=";
          }
        } -C $out/bin
        chmod +x $out/bin/llama-swap
      '';
        };
  };
}
