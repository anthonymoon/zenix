{ config
, lib
, pkgs
, ...
}: {
  # Boot loader configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # File systems will be managed by disko during installation
  # But we need to tell NixOS they will exist
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  swapDevices = [
    {
      device = "/.swap/swapfile";
    }
  ];

  # Network configuration
  networking.hostName = "workstation";

  # Enable NetworkManager for desktop
  networking.networkmanager.enable = true;

  # Enable fish if user amoon exists
  programs.fish.enable = lib.mkDefault true;
}
