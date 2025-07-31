{ config, lib, pkgs, ... }: {
  # Common configuration shared by all hosts
  imports = [
    # System-wide configurations
    ../../system/nix
    ../../nixpkgs

    # Common services
    ../../services/networking/ssh.nix
    ../../services/system/systemd.nix

    # Security baseline
    ../../security/pam
    ../../security/sysctl

    # Base packages
    ../../environment/systemPackages

    # Font configuration
    ../../fonts/packages.nix
  ];

  # Common system settings
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # Common boot settings
  boot = {
    tmp.cleanOnBoot = true;
    kernel.sysctl = { "kernel.sysrq" = 1; };
  };

  # Enable flakes by default
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
