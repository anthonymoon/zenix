{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "w11-vm";

  # VM-specific settings for w11
  system.stateVersion = "24.11";

  # Any w11-vm specific settings go here
  # This would typically be the same software config as w11
  # but with VM-optimized hardware settings
}
