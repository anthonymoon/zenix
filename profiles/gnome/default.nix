{ config
, lib
, pkgs
, ...
}: {
  # Enable GNOME with Wayland
  services.xserver = {
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    desktopManager.gnome.enable = true;
  };

  # GNOME packages
  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.gsconnect
  ];

  # Remove some default GNOME apps
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome.geary
    gnome.gnome-music
  ];

  # Enable GNOME features
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
}
