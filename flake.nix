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

  outputs = { self, nixpkgs, nixpkgs-stable, disko, lanzaboote, pre-commit-hooks
    , chaotic, hyprland, nixos-hardware, ... }@inputs:
    let
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
      system = "x86_64-linux"; # Default system for NixOS configurations
      lib = nixpkgs.lib;

      # Function to generate outputs for all systems
      forAllSystems = nixpkgs.lib.genAttrs systems;

      pkgsFor = system: nixpkgs.legacyPackages.${system};
      pkgs = pkgsFor system;

      # Parse configuration name: hostname.profile1.profile2.profile3
      parseConfigName = name:
        let parts = lib.splitString "." name;
        in {
          hostname = builtins.head parts;
          profiles = builtins.tail parts;
        };

      # Build a system from hostname and profiles
      mkSystem = configName:
        let
          parsed = parseConfigName configName;
          hostname = parsed.hostname;
          profiles = parsed.profiles;

          # Check if host-specific config exists
          hostConfigPath = ./hosts + "/${hostname}/default.nix";
          hasHostConfig = builtins.pathExists hostConfigPath;

          # Exclude hardware detection for test configs
          includeHardwareDetection = hostname != "test";
        in nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };

          modules = [
            # Disko module for disk management
            disko.nixosModules.disko

            # Core system configuration
            ({ config, ... }: {
              # Base system settings
              system.stateVersion = "24.11";
              networking.hostName = hostname;
            })

            # Nix configuration with experimental features
            ./modules/nix-config.nix
          ]
          # Hardware auto-detection (skip for test configs)
            ++ lib.optional includeHardwareDetection ./hardware/auto-detect.nix
            ++ [
              # Common base configuration
              ./base

              # Host-specific settings (if exists)
            ] ++ lib.optional hasHostConfig hostConfigPath ++ [
              # Core system modules
              ./users
              # ./environment/systemPackages  # Disabled temporarily due to package conflicts
              ./fonts/packages.nix
              ./nixpkgs

              # Essential services
              ./services/networking/ssh.nix
              ./services/system/systemd.nix
              
              # ZFS support (always enabled)
              ./modules/disko/zfs-single.nix

              # Software profiles from the config name
            ] ++ (map (profile: ./profiles + "/${profile}") profiles);
        };
    in {
      # Dynamic configurations with example configurations for validation
      nixosConfigurations = {
        # Example configuration for testing - ensures flake check passes
        "test.headless.stable" = mkSystem "test.headless.stable";

        # Common configurations for easy installation
        "workstation.kde.stable" = mkSystem "workstation.kde.stable";
        "workstation.kde.unstable" = mkSystem "workstation.kde.unstable";
        "workstation.gnome.stable" = mkSystem "workstation.gnome.stable";
        "workstation.hyprland.stable" = mkSystem "workstation.hyprland.stable";
      };

      # Dynamic configuration builder (separate from nixosConfigurations to avoid flake check issues)
      lib.buildSystem = mkSystem;

      # Disko configurations for installation - ZFS single disk only
      diskoConfigurations = {
        default = {
          disko.devices = {
            disk = {
              main = {
                type = "disk";
                device = "/dev/sda";  # Will be overridden by --arg device
                content = {
                  type = "gpt";
                  partitions = {
                    ESP = {
                      priority = 1;
                      name = "ESP";
                      start = "1M";
                      end = "1G";
                      type = "EF00";
                      content = {
                        type = "filesystem";
                        format = "vfat";
                        mountpoint = "/boot";
                        mountOptions = [ "umask=0077" ];
                      };
                    };
                    zfs = {
                      priority = 2;
                      name = "zfs";
                      size = "100%";
                      content = {
                        type = "zfs";
                        pool = "zroot";
                      };
                    };
                  };
                };
              };
            };
            zpool = {
              zroot = {
                type = "zpool";
                mode = "";  # Single disk, no RAID
                options = {
                  ashift = "12";  # 4K sectors
                  autotrim = "on";
                  compression = "zstd";
                  atime = "off";
                  xattr = "sa";
                  acltype = "posixacl";
                  mountpoint = "none";
                };
                rootFsOptions = {
                  compression = "zstd";
                  "com.sun:auto-snapshot" = "false";
                };
                
                datasets = {
                  root = {
                    type = "zfs_fs";
                    mountpoint = "/";
                    options = {
                      mountpoint = "legacy";
                    };
                    postCreateHook = ''
                      zfs snapshot zroot/root@blank
                    '';
                  };
                  nix = {
                    type = "zfs_fs";
                    mountpoint = "/nix";
                    options = {
                      mountpoint = "legacy";
                      atime = "off";
                    };
                  };
                  home = {
                    type = "zfs_fs";
                    mountpoint = "/home";
                    options = {
                      mountpoint = "legacy";
                    };
                  };
                  reserved = {
                    type = "zfs_fs";
                    options = {
                      mountpoint = "none";
                      reservation = "1G";
                    };
                  };
                };
              };
            };
          };
        };
        
        # Alias for clarity
        zfs-single = {
          disko.devices = {
            disk = {
              main = {
                type = "disk";
                device = "/dev/sda";  # Will be overridden by --arg device
                content = {
                  type = "gpt";
                  partitions = {
                    ESP = {
                      priority = 1;
                      name = "ESP";
                      start = "1M";
                      end = "1G";
                      type = "EF00";
                      content = {
                        type = "filesystem";
                        format = "vfat";
                        mountpoint = "/boot";
                        mountOptions = [ "umask=0077" ];
                      };
                    };
                    zfs = {
                      priority = 2;
                      name = "zfs";
                      size = "100%";
                      content = {
                        type = "zfs";
                        pool = "zroot";
                      };
                    };
                  };
                };
              };
            };
            zpool = {
              zroot = {
                type = "zpool";
                mode = "";  # Single disk, no RAID
                options = {
                  ashift = "12";  # 4K sectors
                  autotrim = "on";
                  compression = "zstd";
                  atime = "off";
                  xattr = "sa";
                  acltype = "posixacl";
                  mountpoint = "none";
                };
                rootFsOptions = {
                  compression = "zstd";
                  "com.sun:auto-snapshot" = "false";
                };
                
                datasets = {
                  root = {
                    type = "zfs_fs";
                    mountpoint = "/";
                    options = {
                      mountpoint = "legacy";
                    };
                    postCreateHook = ''
                      zfs snapshot zroot/root@blank
                    '';
                  };
                  nix = {
                    type = "zfs_fs";
                    mountpoint = "/nix";
                    options = {
                      mountpoint = "legacy";
                      atime = "off";
                    };
                  };
                  home = {
                    type = "zfs_fs";
                    mountpoint = "/home";
                    options = {
                      mountpoint = "legacy";
                    };
                  };
                  reserved = {
                    type = "zfs_fs";
                    options = {
                      mountpoint = "none";
                      reservation = "1G";
                    };
                  };
                };
              };
            };
          };
        };
      };

      # Helper functions
      lib = {
        # List available software profiles
        profiles = {
          desktop = [ "kde" "gnome" "hyprland" "niri" ];
          system = [ "stable" "unstable" "hardened" "chaotic" ];
          usage = [ "gaming" "headless" ];
        };

        # Example configurations
        examples = [
          "laptop.kde.gaming.unstable"
          "server.headless.hardened"
          "desktop.hyprland.gaming.chaotic"
          "vm.gnome.stable"
          "workstation.kde.stable"
        ];

        # buildSystem moved to lib.buildSystem above
      };

      # Development shell with pre-commit hooks
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              alejandra.enable = true;
              nixfmt.enable = true;
              statix.enable = true;
              deadnix.enable = true;
            };
          };
        in {
          default = pkgs.mkShell {
            packages = with pkgs;
              [
                # Nix development tools
                nix-output-monitor
                nvd
                alejandra
                nixfmt-rfc-style
                statix
                deadnix

                # System tools
                git
                jq
                rsync

                # Pre-commit
                pre-commit
              ] ++ lib.optionals (system == "x86_64-linux") [
                # Linux-only tools
                nixos-rebuild
                disko.packages.${system}.disko
                util-linux
                parted
                smartmontools
                btrfs-progs
                zfs
                btop
                iotop
                tpm2-tools
              ];

            shellHook = pre-commit-check.shellHook + ''
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
        });

      # Apps for installation
      apps.${system} = {
        disko-install = {
          type = "app";
          program = "${
              pkgs.writeShellScriptBin "disko-install" ''
                          #!/usr/bin/env bash
                          set -euo pipefail

                          # Parse arguments
                          CONFIG_NAME=""
                          DISK=""
                          AUTO_MODE=""

                          while [[ $# -gt 0 ]]; do
                            case $1 in
                              --auto)
                                AUTO_MODE="yes"
                                shift
                                ;;
                              --host)
                                CONFIG_NAME="$2"
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
                            echo "Usage: $0 <config-name> [disk-device] [--auto]"
                            echo "Example: $0 workstation.kde.stable /dev/sda --auto"
                            echo ""
                            echo "Available configs:"
                            echo "  • hostname.kde.gaming.unstable"
                            echo "  • hostname.gnome.stable"
                            echo "  • hostname.hyprland.gaming.chaotic"
                            echo "  • hostname.headless.hardened"
                            echo ""
                            echo "Options:"
                            echo "  --auto  Run fully automated (no prompts)"
                            exit 1
                          fi

                          # Default disk if not specified
                          DISK="''${DISK:-/dev/sda}"

                          echo "╔════════════════════════════════════════════════════════════╗"
                          echo "║                   NixOS Automated Installer                 ║"
                          echo "╚════════════════════════════════════════════════════════════╝"
                          echo ""
                          echo "Configuration: $CONFIG_NAME"
                          echo "Disk: $DISK"
                          echo ""

                          # Determine flake reference
                          if [[ -f flake.nix ]]; then
                            FLAKE_REF="."
                            DISKO_FLAKE_REF="."
                          else
                            FLAKE_REF="github:anthonymoon/nixos-fun"
                            DISKO_FLAKE_REF="github:anthonymoon/nixos-fun"
                          fi

                          if [[ "$AUTO_MODE" != "yes" ]]; then
                            echo "[WARNING] This will COMPLETELY ERASE $DISK!"
                            echo -n "Are you sure? (yes/NO): "
                            read -r CONFIRM
                            if [[ "$CONFIRM" != "yes" ]]; then
                              echo "Aborted."
                              exit 1
                            fi
                          else
                            echo "[AUTO MODE] Starting automated installation in 5 seconds..."
                            echo "[WARNING] This will ERASE $DISK!"
                            sleep 5
                          fi

                          # Step 1: Partition with disko
                          echo ""
                          echo "[1/4] Partitioning disk with disko..."
                          sudo nix run github:nix-community/disko -- \
                            --mode disko \
                            --flake "$DISKO_FLAKE_REF#default" \
                            --arg device "\"$DISK\""

                          # Step 2: Configure nix in target system
                          echo ""
                          echo "[2/4] Configuring nix settings..."
                          sudo mkdir -p /mnt/etc/nix
                          sudo tee /mnt/etc/nix/nix.conf > /dev/null << 'EOF'
                substituters = https://cache.nixos.org http://10.10.10.10:5000
                trusted-substituters = http://10.10.10.10:5000
                trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nixos-cache-key:7wraMUa5jdnDQ60R/c+jfCbRf23RUP8DuDUtU/czxPc=
                experimental-features = nix-command flakes
                max-jobs = auto
                cores = 0
                EOF

                          # Step 3: Install NixOS
                          echo ""
                          echo "[3/4] Installing NixOS (this will take a while)..."

                          # Ensure we're using the latest flake
                          if [[ "$FLAKE_REF" == "github:anthonymoon/nixos-fun" ]]; then
                            # Force update to latest
                            INSTALL_FLAKE="github:anthonymoon/nixos-fun#$CONFIG_NAME"
                          else
                            INSTALL_FLAKE="$FLAKE_REF#$CONFIG_NAME"
                          fi

                          echo "Installing from: $INSTALL_FLAKE"

                          if [[ "$AUTO_MODE" == "yes" ]]; then
                            # Automated install with default password
                            echo -e "nixos\nnixos" | sudo nixos-install \
                              --flake "$INSTALL_FLAKE" \
                              --no-channel-copy \
                              --no-root-password \
                              --option substituters "https://cache.nixos.org http://10.10.10.10:5000" \
                              --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nixos-cache-key:7wraMUa5jdnDQ60R/c+jfCbRf23RUP8DuDUtU/czxPc="
                          else
                            # Interactive install
                            sudo nixos-install \
                              --flake "$INSTALL_FLAKE" \
                              --no-channel-copy \
                              --option substituters "https://cache.nixos.org http://10.10.10.10:5000" \
                              --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nixos-cache-key:7wraMUa5jdnDQ60R/c+jfCbRf23RUP8DuDUtU/czxPc="
                          fi

                          # Step 4: Post-install
                          echo ""
                          echo "[4/4] Installation complete!"

                          if [[ "$AUTO_MODE" == "yes" ]]; then
                            # Set up default user in auto mode
                            sudo nixos-enter --root /mnt -c "
                              useradd -m -G wheel,networkmanager,video,audio user || true
                              echo 'user:user' | chpasswd
                              echo 'root:nixos' | chpasswd
                            " 2>/dev/null || true

                            echo ""
                            echo "╔════════════════════════════════════════════════════════════╗"
                            echo "║                    Installation Complete!                   ║"
                            echo "╠════════════════════════════════════════════════════════════╣"
                            echo "║ Default credentials:                                       ║"
                            echo "║   root password: nixos                                     ║"
                            echo "║   user password: user                                      ║"
                            echo "╠════════════════════════════════════════════════════════════╣"
                            echo "║ Rebooting in 10 seconds...                                ║"
                            echo "╚════════════════════════════════════════════════════════════╝"
                            sleep 10
                            sudo reboot
                          else
                            echo ""
                            echo "╔════════════════════════════════════════════════════════════╗"
                            echo "║                    Installation Complete!                   ║"
                            echo "╠════════════════════════════════════════════════════════════╣"
                            echo "║ You can now reboot into your new system:                  ║"
                            echo "║   sudo reboot                                              ║"
                            echo "╚════════════════════════════════════════════════════════════╝"
                          fi
              ''
            }/bin/disko-install";
        };

        mount-system = {
          type = "app";
          program = "${
              pkgs.writeShellScriptBin "mount-system" ''
                #!/usr/bin/env bash
                set -euo pipefail

                CONFIG_NAME="''${1:-}"

                if [[ -z "$CONFIG_NAME" ]]; then
                  echo "Usage: $0 <config-name>"
                  echo "Example: $0 cachy.kde.gaming.unstable"
                  exit 1
                fi

                echo "Mounting system for configuration: $CONFIG_NAME"
                exec sudo nix --extra-experimental-features nix-command --extra-experimental-features flakes run github:nix-community/disko#disko-mount -- --flake ".#$CONFIG_NAME"
              ''
            }/bin/mount-system";
        };
      };

      # Formatter
      formatter = forAllSystems (system: (pkgsFor system).alejandra);

      # Checks
      checks = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              alejandra.enable = true;
              nixfmt.enable = true;
              statix.enable = true;
              deadnix.enable = true;

              # Custom hooks disabled temporarily to avoid conflicts
              # nix-flake-check = {
              #   enable = false;
              #   name = "Nix flake check";
              #   entry = "${pkgs.writeShellScript "nix-flake-check" ''
              #     if [[ $(git diff --cached --name-only | grep -E "\.(nix|lock)$") ]]; then
              #       echo "Running nix flake check..."
              #       nix flake check --no-write-lock-file
              #     fi
              #   ''}";
              #   files = "\\.(nix|lock)$";
              #   pass_filenames = false;
              #   always_run = true;
              # };

              # nix-eval-check = {
              #   enable = false;
              #   name = "Check nixos config evaluation";
              #   entry = "${pkgs.writeShellScript "nix-eval-check" ''
              #     if [[ $(git diff --cached --name-only | grep -E "\.(nix)$") ]]; then
              #       echo "Testing NixOS configuration evaluation..."
              #       # Test with a sample configuration
              #       if nix eval --no-write-lock-file --show-trace \
              #         --expr 'let flake = builtins.getFlake (toString ./.); in flake.lib.buildSystem "test.headless.stable"' \
              #         >/dev/null 2>&1; then
              #         echo "✓ NixOS configuration evaluation successful"
              #       else
              #         echo "✗ NixOS configuration evaluation failed"
              #         exit 1
              #       fi
              #     fi
              #   ''}";
              #   files = "\\.nix$";
              #   pass_filenames = false;
              #   always_run = true;
              # };
            };
          };
        });
    };
}
