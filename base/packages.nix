{ config
, lib
, pkgs
, ...
}: {
  # Core packages that should be available on all systems
  environment.systemPackages = with pkgs; [
    # AI/ML Tools
    # Note: Some AI tools may need to be installed via other methods
    # claude-desktop  # Not in nixpkgs - install via official website
    # claude-code    # Not in nixpkgs - install via official website  
    # gemini         # Not in nixpkgs - use web interface
    # lmstudio       # Not in nixpkgs - install via official website
    ollama          # Local LLM runner (alternative to lmstudio)

    # Graphics/Gaming
    vulkan-tools
    vulkan-loader
    vulkan-headers
    vulkan-validation-layers
    steam
    steam-run

    # Essential system utilities
    vim
    git
    curl
    wget
    htop
    btop
    tmux
    tree
    ripgrep
    fd
    jq
    yq
    bat
    eza
    zoxide
    fzf

    # Development essentials
    neovim
    vscode.fhs  # VSCode with FHS environment support
    gcc
    gnumake
    python3
    nodejs
    rustc
    cargo
    
    # Version control and collaboration
    gh  # GitHub CLI
    gitlab  # GitLab CLI
    gitlab-runner

    # System monitoring
    iotop
    iftop
    nethogs
    # dool  # Not in nixpkgs - use dstat or sar instead
    bandwhich

    # Network tools
    nmap
    netcat
    socat
    mtr
    dig
    whois

    # Archive tools
    zip
    unzip
    p7zip
    unrar

    # Disk utilities
    gparted
    ncdu
    # duf  # Not in nixpkgs - use df instead
    smartmontools
    nvme-cli

    # Container/Virtualization basics
    podman
    podman-compose
    docker-compose

    # Media essentials
    ffmpeg
    mpv
    imagemagick

    # Security tools
    gnupg
    age
    sops
    pass

    # File management
    ranger
    nnn
    # xplr  # May not be in stable nixpkgs
  ];
}