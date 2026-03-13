# AI and machine learning services (Ollama, llama-swap, Wyoming, Qdrant)
{ pkgs, ... }:

{

  # --- llama-swap Service ---
  # Transparent proxy for automatic model swapping with llama.cpp
  # GPT-OSS chat template directly from HuggingFace
  environment.etc."llama-templates/openai-gpt-oss-20b.jinja".source = pkgs.fetchurl {
    url = "https://huggingface.co/unsloth/gpt-oss-20b-GGUF/resolve/main/template";
    sha256 = "sha256-UUaKD9kBuoWITv/AV6Nh9t0z5LPJnq1F8mc9L9eaiUM=";
  };

  # environment.etc."llama-templates/apriel-thinker.jinja".source = ./apriel-thinker.jinja;

  environment.etc."llama-swap/config.yaml".text = ''
    # llama-swap configuration
    # This config uses llama.cpp's server to serve models on demand

    models:  # Ordered from newest to oldest

      # Qwen3.5-35B-A3B - MoE model with 35B total / 3B active params
      "qwen3.5:35b-a3b-q4":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf unsloth/Qwen3.5-35B-A3B-GGUF:UD-Q4_K_XL
          --port ''${PORT}
          --ctx-size 65536
          --batch-size 2048
          --ubatch-size 512
          --threads 1
          --jinja

    healthCheckTimeout: 28800  # 8 hours for large model download + loading

    # TTL keeps models in memory for specified seconds after last use
    ttl: 3600  # Keep models loaded for 1 hour (like OLLAMA_KEEP_ALIVE)

    # Groups allow running multiple models simultaneously
    groups:
      embedding:
        # Keep embedding model always loaded alongside any other model
        persistent: true  # Prevents other groups from unloading this
        swap: false       # Don't swap models within this group
        exclusive: false  # Don't unload other groups when loading this
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
      ExecStart = "${pkgs.llama-swap}/bin/llama-swap --config /etc/llama-swap/config.yaml --listen 0.0.0.0:9292 --watch-config";
      Restart = "always";
      RestartSec = 10;
      # Environment for CUDA support
      # Environment = [
      #   "PATH=/run/current-system/sw/bin"
      #   "LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib"
      #   # llama-swap can use both GPUs (0,1), but Ollama is restricted to GPU 0
      # ];
      # Environment needs access to cache directories for model downloads
      # Simplified security settings to avoid namespace issues
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

}