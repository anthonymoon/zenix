{ config
, lib
, pkgs
, ...
}: {
  # Test host configuration - completely minimal for testing

  # Override problematic options
  system.nixos.label = lib.mkForce "test-system";

  # File systems (highest priority)
  fileSystems = lib.mkForce {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "subvol=@" "compress=zstd" "noatime" ];
    };
    "/home" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "subvol=@home" "compress=zstd" "noatime" ];
    };
    "/nix" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "subvol=@nix" "compress=zstd" "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
  };

  # Boot loader configuration (highest priority)
  boot.loader = lib.mkForce {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    grub.enable = false;
  };

  # Swap file
  swapDevices = lib.mkForce [
    {
      device = "/.swap/swapfile";
      size = 1024; # 1GB for testing
    }
  ];

  # Enable fish shell since amoon user uses it
  programs.fish.enable = true;

  # Disable hardware detection that's causing issues
  hardware = {
    enableAllFirmware = lib.mkForce false;
    graphics.enable = lib.mkForce false;
    bluetooth.enable = lib.mkForce false;
    pulseaudio.enable = lib.mkForce false;
  };

  # Override problematic settings for test environment
  powerManagement.enable = lib.mkForce false;
  services.xserver.enable = lib.mkForce false;
  networking.wireless.enable = lib.mkForce false;
}
