{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable Plymouth boot splash
  boot = {
    plymouth = {
      enable = true;

      # Use a nice theme
      theme = lib.mkDefault "bgrt"; # BGRT shows OEM logo if available

      # Alternative themes to consider:
      # theme = "breeze";
      # theme = "spinner";
      # theme = "solar";

      # Extra config for Plymouth
      extraConfig = ''
        DeviceScale=1
        ShowDelay=0
      '';
    };

    # Silent boot for cleaner experience
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    # Hide boot messages
    consoleLogLevel = 0;

    # Initrd settings for Plymouth
    initrd = {
      verbose = false;

      # Ensure Plymouth works in initrd
      systemd.enable = lib.mkDefault true;
    };
  };

  # Additional Plymouth themes
  environment.systemPackages = with pkgs; [
    plymouth
    # Additional themes if desired
    # plymouth-themes
  ];
}
