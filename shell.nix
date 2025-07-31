# Compatibility shell.nix for non-flake users
{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:
pkgs.mkShell {
  name = "zenix-dev-shell";

  buildInputs = with pkgs; [
    # Nix tools
    nix
    nixfmt-rfc-style
    alejandra
    statix
    deadnix
    nix-output-monitor
    nvd

    # Git and development tools
    git
    pre-commit
    direnv

    # Additional tools
    jq
    yq
    ripgrep
    fd

    # For scripts
    bash
    shellcheck
    shfmt

    # Documentation
    mdbook
    pandoc
  ];

  shellHook = ''
    echo "🚀 Zenix Development Shell (compatibility mode)"
    echo ""
    echo "This is the non-flake development shell."
    echo "For full features, use: nix develop"
    echo ""

    # Set up git hooks
    if [[ -d .git ]] && command -v pre-commit &> /dev/null; then
      pre-commit install 2>/dev/null || true
    fi

    # Source .envrc if direnv is not active
    if [[ -z "$DIRENV_DIR" ]] && [[ -f .envrc ]]; then
      echo "Tip: Install direnv for automatic environment loading"
      echo "     brew install direnv  # macOS"
      echo "     nix-env -iA nixpkgs.direnv  # Nix"
    fi
  '';

  # Environment variables
  NIX_SHELL_PRESERVE_PROMPT = 1;
  NIXPKGS_ALLOW_UNFREE = 1;
}
