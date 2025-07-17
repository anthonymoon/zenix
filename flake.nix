{
  description = "Dynamic NixOS configuration with auto-detected hardware";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";

    # Disk management and installation
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secure boot support
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pre-commit hooks
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    disko,
    lanzaboote,
    pre-commit-hooks,
    chaotic,
    hyprland,
    nixos-hardware,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    lib = nixpkgs.lib;

    pkgs = nixpkgs.legacyPackages.${system};

    # Pre-commit hooks configuration
    pre-commit-check = pre-commit-hooks.lib.${system}.run {
      src = ./.;
      hooks = {
        alejandra.enable = true;
        statix.enable = true;
        deadnix.enable = true;

        # Custom hooks
        nix-flake-check = {
          enable = true;
          name = "Nix flake check";
          entry = "${pkgs.writeShellScript "nix-flake-check" ''
            if [[ $(git diff --cached --name-only | grep -E "\.(nix|lock)$") ]]; then
              echo "Running nix flake check..."
              nix flake check --no-write-lock-file
            fi
          ''}";
          files = "\\.(nix|lock)$";
          pass_filenames = false;
          always_run = true;
        };

        nix-eval-check = {
          enable = true;
          name = "Check nixos config evaluation";
          entry = "${pkgs.writeShellScript "nix-eval-check" ''
            if [[ $(git diff --cached --name-only | grep -E "\.(nix)$") ]]; then
              echo "Testing NixOS configuration evaluation..."
              # Test with a sample configuration
              if nix eval --no-write-lock-file --show-trace \
                --expr 'let flake = builtins.getFlake (toString ./.); in flake.lib.buildSystem "test.headless.stable"' \
                >/dev/null 2>&1; then
                echo "✓ NixOS configuration evaluation successful"
              else
                echo "✗ NixOS configuration evaluation failed"
                exit 1
              fi
            fi
          ''}";
          files = "\\.nix$";
          pass_filenames = false;
          always_run = true;
        };
      };
    };

    # Parse configuration name: hostname.profile1.profile2.profile3
    parseConfigName = name: let
      parts = lib.splitString "." name;
    in {
      hostname = builtins.head parts;
      profiles = builtins.tail parts;
    };

    # Build a system from hostname and profiles
    mkSystem = configName: let
      parsed = parseConfigName configName;
      hostname = parsed.hostname;
      profiles = parsed.profiles;

      # Check if host-specific config exists
      hostConfigPath = ./hosts + "/${hostname}/default.nix";
      hasHostConfig = builtins.pathExists hostConfigPath;
    in
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};

        modules =
          [
            # Disko module for disk management
            disko.nixosModules.disko

            # Core system configuration
            ({config, ...}: {
              # Base system settings
              system.stateVersion = "24.11";
              networking.hostName = hostname;
            })

            # Nix configuration with experimental features
            ./modules/nix-config.nix

            # Hardware auto-detection (always included)
            ./hardware/auto-detect.nix

            # Common base configuration
            ./base

            # Host-specific settings (if exists)
          ]
          ++ lib.optional hasHostConfig hostConfigPath
          ++ [
            # Core system modules
            ./users
            ./environment/systemPackages
            ./fonts/packages.nix
            ./nixpkgs

            # Essential services
            ./services/networking/ssh.nix
            ./services/system/systemd.nix

            # Software profiles from the config name
          ]
          ++ (map (profile: ./profiles + "/${profile}") profiles);
      };
  in {
    # Dynamic configurations with example configurations for validation
    nixosConfigurations = {
      # Example configuration for testing - ensures flake check passes
      "test.headless.stable" = mkSystem "test.headless.stable";

      # The __functor allows any hostname.profile.profile syntax
      __functor = self: configName: mkSystem configName;
    };

    # Helper functions
    lib = {
      # List available software profiles
      profiles = {
        desktop = ["kde" "gnome" "hyprland" "niri"];
        system = ["stable" "unstable" "hardened" "chaotic"];
        usage = ["gaming" "headless"];
      };

      # Example configurations
      examples = [
        "laptop.kde.gaming.unstable"
        "server.headless.hardened"
        "desktop.hyprland.gaming.chaotic"
        "vm.gnome.stable"
        "workstation.kde.stable"
      ];

      # Build function exposed for testing
      buildSystem = mkSystem;
    };

    # Development shell with pre-commit hooks
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        # Nix development tools
        nixos-rebuild
        nix-output-monitor
        nvd
        alejandra
        statix
        deadnix

        # Disko and installation tools
        disko.packages.${system}.disko
        util-linux
        parted
        smartmontools

        # System tools
        git
        jq
        rsync

        # Filesystem tools
        btrfs-progs
        zfs

        # Monitoring and debugging
        btop
        iotop

        # TPM tools (for encryption)
        tpm2-tools

        # Pre-commit
        pre-commit
      ];

      shellHook =
        pre-commit-check.shellHook
        + ''
          echo ""
          echo "🚀 NixOS Multi-Host Development Environment"
          echo "==========================================="
          echo ""
          echo "📦 Installation commands:"
          echo "  ./scripts/install-interactive.sh    # Interactive installer"
          echo "  ./scripts/install-host.sh <config>  # Direct installation"
          echo ""
          echo "🔧 Manual disko commands:"
          echo "  sudo nix run github:nix-community/disko/latest#disko-install -- --flake .#hostname.profile"
          echo ""
          echo "🔄 System rebuild:"
          echo "  sudo nixos-rebuild switch --flake .#hostname.profile"
          echo ""
          echo "📋 Available configurations:"
          echo "  • hostname.kde.gaming.unstable"
          echo "  • hostname.gnome.stable"
          echo "  • hostname.headless.hardened"
          echo "  • hostname.hyprland.gaming.chaotic"
          echo ""
          echo "🛠️  Development commands:"
          echo "  nix flake update      # Update dependencies"
          echo "  nix fmt              # Format code"
          echo "  pre-commit run --all # Run all hooks"
          echo "  git commit           # Commit with pre-commit checks"
          echo ""
          echo "🗄️  Available filesystems:"
          echo "  • btrfs-single: Single disk Btrfs"
          echo "  • btrfs-luks:   Encrypted Btrfs with TPM2"
          echo "  • zfs-single:   Single disk ZFS"
          echo "  • zfs-luks:     Encrypted ZFS with TPM2"
          echo ""
        '';
    };

    # Apps for installation
    apps.${system} = {
      disko-install = {
        type = "app";
        program = "${pkgs.writeShellScriptBin "disko-install" ''
          #!/usr/bin/env bash
          set -euo pipefail

          # Parse arguments
          CONFIG_NAME=""
          DISK=""

          while [[ $# -gt 0 ]]; do
            case $1 in
              --host)
                CONFIG_NAME="$2"
                shift 2
                ;;
              --disk-config)
                # Skip disk config parameter (we'll use the config name)
                shift 2
                ;;
              --disk)
                DISK="$2"
                shift 2
                ;;
              *)
                if [[ -z "$CONFIG_NAME" ]]; then
                  CONFIG_NAME="$1"
                elif [[ -z "$DISK" ]]; then
                  DISK="$1"
                fi
                shift
                ;;
            esac
          done

          if [[ -z "$CONFIG_NAME" ]]; then
            echo "Usage: $0 <config-name> [disk-device]"
            echo "Example: $0 cachy.kde.gaming.unstable /dev/sda"
            echo "Available configs:"
            echo "  • hostname.kde.gaming.unstable"
            echo "  • hostname.gnome.stable"
            echo "  • hostname.hyprland.gaming.chaotic"
            echo "  • hostname.headless.hardened"
            exit 1
          fi

          echo "NixOS Disko Installer"
          echo "===================="
          echo "Configuration: $CONFIG_NAME"

          if [[ -n "$DISK" ]]; then
            echo "Disk: $DISK"
            exec sudo nix run github:nix-community/disko#disko-install -- \
              --flake ".#$CONFIG_NAME" --disk main "$DISK" --write-efi-boot-entries
          else
            echo "Using auto-detected disk"
            exec sudo nix run github:nix-community/disko#disko-install -- \
              --flake ".#$CONFIG_NAME" --write-efi-boot-entries
          fi
        ''}/bin/disko-install";
      };

      mount-system = {
        type = "app";
        program = "${pkgs.writeShellScriptBin "mount-system" ''
          #!/usr/bin/env bash
          set -euo pipefail

          CONFIG_NAME="''${1:-}"

          if [[ -z "$CONFIG_NAME" ]]; then
            echo "Usage: $0 <config-name>"
            echo "Example: $0 cachy.kde.gaming.unstable"
            exit 1
          fi

          echo "Mounting system for configuration: $CONFIG_NAME"
          exec sudo nix run github:nix-community/disko#disko-mount -- --flake ".#$CONFIG_NAME"
        ''}/bin/mount-system";
      };
    };

    # Formatter
    formatter.${system} = pkgs.alejandra;

    # Checks
    checks.${system} = {
      pre-commit-check = pre-commit-check;
    };
  };
}
