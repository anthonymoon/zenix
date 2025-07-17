{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./default.nix
    ./local-cache.nix
    ./cache-optimization.nix
    ./distributed-builds.nix
  ];

  # Main cache configuration combining all features
  nix.settings = {
    # Ordered substituters (local cache first)
    substituters = lib.mkForce [
      "http://localhost:5000" # Local cache (highest priority)
      "https://cache.nixos.org/" # Official NixOS cache
      "https://nix-community.cachix.org" # Community cache
    ];

    # Trust all configured substituters
    trusted-substituters = lib.mkForce [
      "http://localhost:5000"
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];

    # Add experimental features for better caching
    experimental-features = lib.mkForce [
      "nix-command"
      "flakes"
      "ca-derivations" # Content-addressed derivations
      "recursive-nix" # Allow Nix expressions to build Nix expressions
      "impure-derivations" # For special build requirements
    ];
  };
}
