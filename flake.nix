{
  description = "Dynamic NixOS configuration with auto-detected hardware";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, chaotic, hyprland, nixos-hardware, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      
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
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          
          modules = [
            # Core system configuration
            ({ config, ... }: {
              # Base system settings
              system.stateVersion = "24.11";
              networking.hostName = hostname;
              
              # Nix settings
              nix.settings = {
                experimental-features = [ "nix-command" "flakes" ];
                auto-optimise-store = true;
              };
            })
            
            # Hardware auto-detection (always included)
            ./hardware/auto-detect.nix
            
            # Common base configuration
            ./base
            
            # Host-specific settings (if exists)
          ] ++ lib.optional hasHostConfig hostConfigPath ++ [
            
            # Core system modules
            ./users
            ./environment/systemPackages
            ./fonts/packages.nix
            ./nixpkgs
            
            # Essential services
            ./services/networking/ssh.nix
            ./services/system/systemd.nix
            
            # Software profiles from the config name
          ] ++ (map (profile: ./profiles + "/${profile}") profiles);
        };
      
    in
    {
      # Dynamic configurations only - no hardcoded entries
      nixosConfigurations = {
        # The __functor allows any hostname.profile.profile syntax
        __functor = self: configName: mkSystem configName;
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
        
        # Build function exposed for testing
        buildSystem = mkSystem;
      };
    };
}