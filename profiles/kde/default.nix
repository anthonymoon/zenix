{
  config,
  lib,
  pkgs,
  ...
}: {
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
  };

  # KDE packages
  environment.systemPackages = with pkgs; [
    ark
    dolphin
    kate
    kdeconnect
    kdenlive
    konsole
    okular
    plasma-browser-integration
    spectacle
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
