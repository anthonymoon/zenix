{ config, lib, pkgs, ... }: {
  # Enable support for various filesystems
  boot = {
    supportedFilesystems = [ "btrfs" "xfs" "ntfs" "vfat" "exfat" "apfs" ];

    # Kernel modules for filesystems
    kernelModules = [ "btrfs" "xfs" "ntfs3" "vfat" "exfat" ];
  };

  # Filesystem utilities
  environment.systemPackages = with pkgs; [
    # Btrfs tools
    btrfs-progs
    compsize

    # XFS tools
    xfsprogs
    xfsdump

    # NTFS tools
    ntfs3g
    ntfsprogs

    # FAT/exFAT tools
    dosfstools
    exfat
    exfatprogs

    # APFS tools (read-only support)
    apfs-fuse

    # General filesystem tools
    fuse
    fuse3
    fuseiso

    # Filesystem analysis
    ncdu
    duf
    dust

    # Recovery tools
    testdisk # includes photorec
    ddrescue
    extundelete
  ];
}
