# AI and machine learning services (Ollama, llama-swap, Wyoming, Qdrant)
{ pkgs, ... }:

let
  # Explicitly build llama-cpp with ROCm support
  llama-cpp-rocm = pkgs.llama-cpp.override { rocmSupport = true; };
in
{
  # Consolidate graphics configuration (use hardware.graphics for NixOS 24.11+)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd # Provides OpenCL/HIP runtimes
      rocmPackages.rocm-cmake
      rocmPackages.rocm-smi-lib
      rocmPackages.hipblas
      rocmPackages.miopen
    ];
  };

  # Add the tools to your system packages
  environment.systemPackages = with pkgs; [
    rocmPackages.rocminfo
    rocmPackages.rocm-smi
    clinfo
  ];

  # Set environment variables for ROCm runtime (Removed LD_LIBRARY_PATH overrides)
  environment.variables = {
    ROCM_PATH = "${pkgs.rocmPackages.rocm-cmake}/rocm";
    HIP_VISIBLE_DEVICES = "0";
  };

  # --- llama-swap Service ---
  environment.etc."llama-templates/openai-gpt-oss-20b.jinja".source = pkgs.fetchurl {
    url = "https://huggingface.co/unsloth/gpt-oss-20b-GGUF/resolve/main/template";
    sha256 = "sha256-UUaKD9kBuoWITv/AV6Nh9t0z5LPJnq1F8mc9L9eaiUM=";
  };

  environment.etc."llama-swap/config.yaml".text = ''
    models:
      "qwen3.5:35b-a3b-q4":
        cmd: |
          ${llama-cpp-rocm}/bin/llama-server
          -hf unsloth/Qwen3.5-35B-A3B-GGUF:UD-Q4_K_XL
          --port ''${PORT}
          --ctx-size 65536
          --batch-size 2048
          --ubatch-size 512
          --threads 1
          --jinja

      "qwen3.5:2b-Q8-O":
        cmd: |
          ${llama-cpp-rocm}/bin/llama-server
          -hf unsloth/Qwen3.5-2B-GGUF:Q8_0
          --port ''${PORT}
          --ctx-size 65536
          --batch-size 2048
          --ubatch-size 512
          --threads 1
          --jinja

    healthCheckTimeout: 28800
    ttl: 3600

    groups:
      embedding:
        persistent: true
        swap: false
        exclusive: false
        members:
          - "embeddinggemma:300m"
  '';

  systemd.services.llama-swap = {
    description = "llama-swap - OpenAI compatible proxy with automatic model swapping";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "zman";
      Group = "users";
      # Give the service access to the GPU
      SupplementaryGroups = [ "video" "render" ]; 
      ExecStart = "${pkgs.llama-swap}/bin/llama-swap --config /etc/llama-swap/config.yaml --listen 0.0.0.0:9292 --watch-config";
      Restart = "always";
      RestartSec = 10;
      
      # Removed the toxic /usr/lib LD_LIBRARY_PATH override. 
      # The Nix-built llama-cpp-rocm package knows where to find its own dependencies.
      Environment = [
        "ROCM_PATH=${pkgs.rocmPackages.rocm-cmake}/rocm"
        "HIP_VISIBLE_DEVICES=0"
      ];
      PrivateTmp = true;
      NoNewPrivileges = false;
    };
  };
}