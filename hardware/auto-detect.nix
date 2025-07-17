{
  config,
  lib,
  pkgs,
  ...
}: let
  # Read system information
  cpuinfo = builtins.readFile /proc/cpuinfo;

  # CPU Detection
  cpuVendor =
    if lib.strings.hasInfix "GenuineIntel" cpuinfo
    then "intel"
    else if lib.strings.hasInfix "AuthenticAMD" cpuinfo
    then "amd"
    else "generic";

  # GPU Detection (check for kernel modules)
  hasNvidia =
    builtins.pathExists /sys/module/nvidia
    || builtins.pathExists /dev/nvidia0;
  hasAmdGpu =
    builtins.pathExists /sys/module/amdgpu
    || builtins.pathExists /dev/dri/renderD128;
  hasIntelGpu = builtins.pathExists /sys/module/i915;

  # Virtualization Detection
  isVirtual =
    lib.strings.hasInfix "hypervisor" cpuinfo
    || builtins.pathExists /sys/hypervisor/type;

  # VM Type Detection
  vmType =
    if !isVirtual
    then null
    else if builtins.pathExists /sys/devices/virtual/dmi/id/sys_vendor
    then let
      vendor = lib.strings.removeSuffix "\n" (builtins.readFile /sys/devices/virtual/dmi/id/sys_vendor);
    in
      if vendor == "QEMU" || vendor == "KVM"
      then "qemu-kvm"
      else if vendor == "VMware, Inc."
      then "vmware"
      else if vendor == "innotek GmbH"
      then "virtualbox"
      else if vendor == "Microsoft Corporation"
      then "hyperv"
      else if vendor == "Xen"
      then "xen"
      else "generic-vm"
    else "generic-vm";
in {
  imports =
    [
      # Always import the detection results module
      (import ./detection-results.nix {
        inherit cpuVendor hasNvidia hasAmdGpu hasIntelGpu isVirtual vmType;
      })

      # Auto-import hardware modules based on detection
      ./modules/cpu-${cpuVendor}.nix
      ./modules/platform-${
        if isVirtual
        then "virtual"
        else "physical"
      }.nix
    ]
    ++
    # GPU modules (can have multiple)
    (lib.optional hasNvidia ./modules/gpu-nvidia.nix)
    ++ (lib.optional hasAmdGpu ./modules/gpu-amd.nix)
    ++ (lib.optional hasIntelGpu ./modules/gpu-intel.nix);

  # Export detection info for debugging
  system.nixos.tags =
    [
      "cpu:${cpuVendor}"
    ]
    ++ (lib.optional hasNvidia "gpu:nvidia")
    ++ (lib.optional hasAmdGpu "gpu:amd")
    ++ (lib.optional hasIntelGpu "gpu:intel")
    ++ (lib.optional isVirtual "vm:${vmType}")
    ++ (lib.optional (!isVirtual) "platform:physical");
}
