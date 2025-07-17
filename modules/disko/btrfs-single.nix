# Btrfs single disk configuration (no encryption)
{ lib, ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = lib.mkDefault "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" "umask=0077" ];
              };
            };
            root = {
              priority = 2;
              name = "root";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Force create
                subvolumes = {
                  # Root subvolume
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  # Home subvolume
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  # Nix store subvolume
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  # Var subvolume
                  "@var" = {
                    mountpoint = "/var";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  # Swap subvolume
                  "@swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = "8G";
                  };
                  # Snapshots subvolume (not mounted by default)
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}