{ config, lib, pkgs, ... }:

{
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
  hardware.sensor.iio.enable = true;
  hardware.video.hidpi.enable = lib.mkDefault true;
}
