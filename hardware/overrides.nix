{
  config,
  lib,
  pkgs,
  ...
}: {
  options.hardware.overrides = {
    cpu = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["intel" "amd" "generic"]);
      default = null;
      description = "Override CPU detection";
    };

    gpu = lib.mkOption {
      type = lib.types.listOf (lib.types.enum ["nvidia" "amd" "intel" "none"]);
      default = [];
      description = "Override GPU detection";
    };

    platform = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["physical" "virtual"]);
      default = null;
      description = "Override platform detection";
    };
  };

  config = lib.mkIf (config.hardware.overrides != {}) {
    # Override detection if specified
    imports =
      # CPU override
      (lib.optional (config.hardware.overrides.cpu == "intel") ./modules/cpu-intel.nix)
      ++ (lib.optional (config.hardware.overrides.cpu == "amd") ./modules/cpu-amd.nix)
      ++
      # GPU overrides
      (lib.optional (builtins.elem "nvidia" config.hardware.overrides.gpu) ./modules/gpu-nvidia.nix)
      ++ (lib.optional (builtins.elem "amd" config.hardware.overrides.gpu) ./modules/gpu-amd.nix)
      ++ (lib.optional (builtins.elem "intel" config.hardware.overrides.gpu) ./modules/gpu-intel.nix)
      ++
      # Platform override
      (lib.optional (config.hardware.overrides.platform == "physical") ./modules/platform-physical.nix)
      ++ (lib.optional (config.hardware.overrides.platform == "virtual") ./modules/platform-virtual.nix);
  };
}
