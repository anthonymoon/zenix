{
  config,
  lib,
  pkgs,
  ...
}: {
  # Kernel modules and settings for advanced hardware support

  boot = {
    # Extra kernel modules
    extraModulePackages = with config.boot.kernelPackages; [
      # Ryzen SMU for AMD CPU monitoring
      ryzen-smu

      # V4L2 loopback for virtual cameras
      v4l2loopback
    ];

    # Load kernel modules at boot
    kernelModules = [
      # AMD Ryzen SMU
      "ryzen_smu"

      # MSR for CPU access
      "msr"

      # Performance monitoring
      "kvm"
      "kvm-amd"
      "kvm-intel"

      # USB and media devices
      "usbhid"
      "hid_generic"

      # Virtual camera support
      "v4l2loopback"
    ];

    # Kernel parameters for advanced features
    kernelParams = [
      # Enable MSR writes (be careful!)
      "msr.allow_writes=on"

      # Better USB device support
      "usbcore.autosuspend=-1"

      # Disable USB autosuspend for Elgato devices
      "usbcore.quirks=0fd9:006c:gki,0fd9:006d:gki,0fd9:006e:gki"
    ];

    # Blacklist conflicting modules
    blacklistedKernelModules = [
      # Blacklist if using proprietary drivers
      "nouveau" # For NVIDIA users
    ];
  };

  # Hardware support packages
  environment.systemPackages = with pkgs; [
    # CPU tools
    ryzen-monitor-ng
    zenmonitor

    # MSR tools
    msr-tools
    cpuid

    # Hardware monitoring
    lm_sensors
    i2c-tools

    # USB tools
    usbutils
    usb-modeswitch

    # V4L2 tools for cameras
    v4l-utils

    # Elgato Stream Deck support
    streamdeck-ui
  ];

  # Services for hardware support
  services = {
    # Enable hardware monitoring
    hardware.bolt.enable = true; # Thunderbolt support

    # Udev rules for Elgato devices
    udev.extraRules = ''
      # Elgato Stream Deck
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006d", MODE="0666", GROUP="users", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0080", MODE="0666", GROUP="users", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006c", MODE="0666", GROUP="users", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0090", MODE="0666", GROUP="users", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006e", MODE="0666", GROUP="users", TAG+="uaccess"

      # Elgato Cam Link
      SUBSYSTEM=="video4linux", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0066", MODE="0666", GROUP="users", TAG+="uaccess"

      # MSR access for monitoring tools
      KERNEL=="msr[0-9]*", MODE="0666"
    '';
  };

  # Security note for MSR access
  warnings =
    lib.optional config.boot.kernelParams
    "MSR write access is enabled. This can be a security risk. Only use with trusted software.";
}
