{ config, lib, pkgs, ... }:

let
  # Detect CPU vendor
  cpuVendor = 
    if builtins.elem "GenuineIntel" (lib.strings.splitString "\n" (builtins.readFile /proc/cpuinfo)) then "intel"
    else if builtins.elem "AuthenticAMD" (lib.strings.splitString "\n" (builtins.readFile /proc/cpuinfo)) then "amd"
    else "generic";
  
  # Detect GPU vendor(s) - can have multiple
  hasNvidia = builtins.pathExists /sys/module/nvidia;
  hasAmdGpu = builtins.pathExists /sys/module/amdgpu;
  hasIntelGpu = builtins.pathExists /sys/module/i915;
  
  # Detect if running in VM
  isVirtual = builtins.elem "hypervisor" (lib.strings.splitString "\n" (builtins.readFile /proc/cpuinfo))
    || builtins.pathExists /sys/devices/virtual/dmi/id/sys_vendor
    && builtins.elem (builtins.readFile /sys/devices/virtual/dmi/id/sys_vendor) ["QEMU" "VMware" "VirtualBox" "Xen"];
in
{
  imports = [
    # Auto-import CPU profile
    (lib.mkIf (cpuVendor == "intel") ../modules/cpu-intel.nix)
    (lib.mkIf (cpuVendor == "amd") ../modules/cpu-amd.nix)
    
    # Auto-import GPU profiles (can have multiple)
    (lib.mkIf hasNvidia ../modules/gpu-nvidia.nix)
    (lib.mkIf hasAmdGpu ../modules/gpu-amd.nix)
    (lib.mkIf hasIntelGpu ../modules/gpu-intel.nix)
    
    # Platform profile
    (lib.mkIf isVirtual ../modules/platform-virtual.nix)
    (lib.mkIf (!isVirtual) ../modules/platform-physical.nix)
  ];
  
  # Export detected hardware for debugging
  system.configurationRevision = lib.mkDefault (
    "CPU: ${cpuVendor} | " +
    "GPU: ${lib.concatStringsSep "+" (lib.optional hasNvidia "nvidia" ++ lib.optional hasAmdGpu "amd" ++ lib.optional hasIntelGpu "intel")} | " +
    "Platform: ${if isVirtual then "virtual" else "physical"}"
  );
}