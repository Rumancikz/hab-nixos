# AI and machine learning services - CUDA/NVIDIA variant
# For use with glacier (NVIDIA RTX 5090)
{ pkgs, ... }:

let
  llama-cpp-cuda = pkgs.llama-cpp.override { cudaSupport = true; };
in
{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # CUDA runtime is handled by hardware.nvidia, not extraPackages
    ];
  };

  environment.systemPackages = with pkgs; [
    cudaPackages.cuda_nvcc
    nvtopPackages.nvidia
  ];

  environment.variables = {
    CUDA_VISIBLE_DEVICES = "0";
  };

  # llama-swap config (same structure as ai.nix, different llama-cpp binary)
  environment.etc."llama-templates/openai-gpt-oss-20b.jinja".source = pkgs.fetchurl {
    url = "https://huggingface.co/unsloth/gpt-oss-20b-GGUF/resolve/main/template";
    sha256 = "sha256-UUaKD9kBuoWITv/AV6Nh9t0z5LPJnq1F8mc9L9eaiUM=";
  };

  environment.etc."llama-swap/config.yaml".text = ''
    models:
      "qwen3.5:35b-a3b-q4":
        cmd: |
          ${llama-cpp-cuda}/bin/llama-server
          -hf unsloth/Qwen3.5-35B-A3B-GGUF:UD-Q4_K_XL
          --port ''${PORT}
          --ctx-size 65536
          --batch-size 2048
          --ubatch-size 512
          --threads 1
          --jinja

      "qwen3.5:2b-Q8-O":
        cmd: |
          ${llama-cpp-cuda}/bin/llama-server
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
      SupplementaryGroups = [ "video" "render" ];
      ExecStart = "${pkgs.llama-swap}/bin/llama-swap --config /etc/llama-swap/config.yaml --listen 0.0.0.0:9292 --watch-config";
      Restart = "always";
      RestartSec = 10;

      Environment = [
        "CUDA_VISIBLE_DEVICES=0"
      ];
      PrivateTmp = true;
      NoNewPrivileges = false;
    };
  };
}
