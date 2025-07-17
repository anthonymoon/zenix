# Btrfs with LUKS2 encryption
{ lib, config, ... }:
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
            luks = {
              priority = 2;
              name = "cryptroot";
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  # LUKS2 with Argon2id
                  keyFile = lib.mkDefault null;
                  allowDiscards = true;
                  crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-pcrs=0+2+7" ];
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # Force create
                  subvolumes = {
                    # Root subvolume
                    "@" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
                    };
                    # Home subvolume
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
                    };
                    # Nix store subvolume
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
                    };
                    # Var subvolume
                    "@var" = {
                      mountpoint = "/var";
                      mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
                    };
                    # Swap subvolume
                    "@swap" = {
                      mountpoint = "/swap";
                      swap.swapfile.size = "8G";
                    };
                    # Snapshots subvolume (not mounted by default)
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Enable systemd-cryptenroll for TPM2 support
  boot.initrd.systemd.enable = lib.mkDefault true;
  boot.initrd.systemd.enableTpm2 = lib.mkDefault true;
}