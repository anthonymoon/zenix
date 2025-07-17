{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];
  
  networking.hostName = "w11";
  
  # Host-specific configuration
  system.stateVersion = "24.11";
  
  # Any w11-specific settings go here
}