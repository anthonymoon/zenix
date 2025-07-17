{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "cachy-vm";

  # VM-specific settings for cachy
  system.stateVersion = "24.11";

  # Any cachy-vm specific settings go here
  # This would typically be the same software config as cachy
  # but with VM-optimized hardware settings
}
