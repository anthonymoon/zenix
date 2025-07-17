{ config, lib, pkgs, ... }:

{
  # AMD GPU configuration (auto-detected)
  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    kernelParams = lib.mkDefault [
      "amdgpu.ppfeaturemask=0xffffffff"
    ];
  };
  
  services.xserver.videoDrivers = lib.mkBefore [ "amdgpu" ];
  
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = lib.mkDefault true;
    extraPackages = with pkgs; [
      amdvlk
      rocm-opencl-icd
      rocm-opencl-runtime
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };
}