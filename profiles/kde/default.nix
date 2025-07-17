{
  config,
  lib,
  pkgs,
  ...
}: {
  # Update to new service names (NixOS 24.11+)
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # KDE packages - use kdePackages namespace for Qt6 versions
  environment.systemPackages = with pkgs; [
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.kdeconnect-kde
    kdePackages.kdenlive
    kdePackages.konsole
    kdePackages.okular
    plasma-browser-integration
    kdePackages.spectacle
  ];

  # Enable KDE partition manager
  programs.partition-manager.enable = true;

  # KDE Connect
  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
  };
}
