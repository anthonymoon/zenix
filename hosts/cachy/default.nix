{ config, lib, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../hardware/detection # Auto-detect hardware
    ../../hardware/overrides # Allow manual overrides
  ];

  networking.hostName = "cachy";

  # Host-specific configuration
  system.stateVersion = "24.11";

  # Hardware overrides (if needed)
  # hardware.overrides = {
  #   cpu = "amd";  # Force AMD CPU profile
  #   gpu = [ "nvidia" "intel" ];  # Force multiple GPUs
  #   platform = "physical";  # Force physical platform
  # };

  # Any cachy-specific settings go here
}
